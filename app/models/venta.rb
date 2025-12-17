require "prawn"
require "prawn/table"

class Venta < ApplicationRecord
  # === ASOCIACIONES ===
  belongs_to :empleado, class_name: "Usuario"
  belongs_to :cliente, optional: true
  has_many :detalle_ventas, dependent: :destroy
  has_many :productos, through: :detalle_ventas
  
  accepts_nested_attributes_for :detalle_ventas, allow_destroy: true

  # === VALIDACIONES ===
  validates :fecha_hora, presence: { message: "no puede estar vacía" }
  validates :empleado, presence: { message: "debe asignarse un vendedor" }
  validates :total, presence: { message: "no puede estar vacío" }, 
            numericality: { greater_than_or_equal_to: 0, message: "debe ser >= 0" }
  validates :pago, presence: { message: "debe seleccionar un medio de pago" }, 
            inclusion: { in: %w[efectivo transferencia debito], message: "medio de pago inválido" }
  validate :debe_tener_al_menos_un_detalle
  validate :detalles_validos

  # === SCOPES ===
  scope :activas, -> { where(cancelada: false) }
  scope :filtrar, ->(params) do
    ventas = left_outer_joins(:cliente).includes(:cliente, :empleado).order(fecha_hora: :desc)

    if params[:q].present?
      q = params[:q].to_s.downcase
      ventas = ventas.where("LOWER(clientes.nombre) LIKE ?", "%#{q}%")
    end

    if params[:empleado_id].present?
      ventas = ventas.where(empleado_id: params[:empleado_id])
    end

    if params[:fecha_inicio].present?
      fecha_inicio = Date.parse(params[:fecha_inicio]) rescue nil
      ventas = ventas.where("fecha_hora >= ?", fecha_inicio.beginning_of_day) if fecha_inicio
    end

    if params[:fecha_fin].present?
      fecha_fin = Date.parse(params[:fecha_fin]) rescue nil
      ventas = ventas.where("fecha_hora <= ?", fecha_fin.end_of_day) if fecha_fin
    end

    ventas
  end

  # Cancela la venta: marca cancelada, setea fecha_cancelacion y repone stock.
  # Operación en transacción para evitar inconsistencias.
  def cancelar!(motivo: nil)
    return false if cancelada

    ActiveRecord::Base.transaction do
      # Reponer stock para cada detalle (usar lock para concurrencia)
      detalle_ventas.each do |dv|
        prod = Producto.lock.find_by(id: dv.producto_id)
        # Si el producto no existe o fue eliminado lógicamente, no reponemos stock
        next unless prod && prod.estado != "eliminado"
        # usar update_column para evitar validaciones que bloqueen la reposición
        prod.update_column(:stock, prod.stock.to_i + dv.cantidad.to_i)
      end

      update!(cancelada: true, fecha_cancelacion: Time.current)
    end

    true
  end

  # LÓGICA DE NEGOCIO: Procesar y validar datos de cliente
  def procesar_cliente_desde_params(dni:, nombre:, telefono: nil)
    return { success: false, error: "DNI y nombre son obligatorios." } if dni.blank? || nombre.blank?
    return { success: false, error: "DNI inválido. Debe contener exactamente 8 dígitos numéricos." } unless dni =~ /\A\d{8}\z/
    return { success: false, error: "Nombre inválido. Sólo letras y espacios, máximo 20 caracteres." } unless nombre =~ /\A[[:alpha:]\s]{1,20}\z/

    if telefono.present? && !(telefono =~ /\A\d{1,20}\z/)
      return { success: false, error: "Teléfono inválido. Sólo números y máximo 20 dígitos." }
    end

    cliente = Cliente.find_or_create_by(dni: dni) do |c|
      c.nombre = nombre
      c.telefono = telefono
    end

    { success: true, cliente: cliente }
  end

  # LÓGICA DE NEGOCIO: Calcular total de la venta
  def calcular_total
    detalles_attrs = detalle_ventas.reject(&:marked_for_destruction?)
    detalles_attrs.sum { |d| d.cantidad.to_i * d.precio.to_f }
  end

  # LÓGICA DE NEGOCIO: Validar y actualizar stock para crear venta
  def validar_y_actualizar_stock_crear
    ActiveRecord::Base.transaction do
      detalle_ventas.each do |dv|
        next if dv.marked_for_destruction?

        producto = Producto.lock.find_by(id: dv.producto_id)
        unless producto
          errors.add(:base, "Producto no encontrado (id=#{dv.producto_id})")
          raise ActiveRecord::Rollback
        end

        if producto.stock.to_i < dv.cantidad.to_i
          errors.add(:base, "No hay stock suficiente para #{producto.titulo}")
          raise ActiveRecord::Rollback
        end
      end

      return false unless save

      detalle_ventas.each do |dv|
        next if dv.marked_for_destruction?
        prod = Producto.lock.find(dv.producto_id)
        new_stock = prod.stock.to_i - dv.cantidad.to_i

        if new_stock < 0
          errors.add(:base, "No hay stock suficiente para #{prod.titulo}")
          raise ActiveRecord::Rollback
        end

        prod.update_column(:stock, new_stock)
      end

      true
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, "Error al actualizar stock: #{e.message}")
    false
  end

  # LÓGICA DE NEGOCIO: Calcular cambios de stock para actualización
  def calcular_cambios_stock(detalles_incoming)
    stock_changes = []

    detalles_incoming.each do |_key, attrs|
      next unless attrs.is_a?(Hash)

      if attrs["_destroy"].to_s == "1"
        if attrs["id"].present?
          dv = detalle_ventas.find_by(id: attrs["id"].to_i)
          stock_changes << { producto_id: dv.producto_id, delta: dv.cantidad.to_i } if dv
        end
        next
      end

      producto_id = attrs["producto_id"].to_i
      cantidad_nueva = attrs["cantidad"].to_i

      if attrs["id"].present?
        dv = detalle_ventas.find_by(id: attrs["id"].to_i)
        cantidad_ant = dv ? dv.cantidad.to_i : 0
        delta_needed = cantidad_nueva - cantidad_ant
      else
        delta_needed = cantidad_nueva
      end

      next if delta_needed == 0

      stock_changes << { producto_id: producto_id, delta_needed: delta_needed }
    end

    stock_changes
  end

  # LÓGICA DE NEGOCIO: Aplicar cambios de stock para actualización
  def aplicar_cambios_stock(stock_changes)
    stock_changes.each do |chg|
      prod = Producto.lock.find_by(id: chg[:producto_id])
      next unless prod

      if chg[:delta_needed]
        if chg[:delta_needed] > 0 && prod.stock.to_i < chg[:delta_needed]
          errors.add(:base, "No hay stock suficiente para #{prod.titulo}")
          raise ActiveRecord::Rollback
        end
        new_stock = prod.stock.to_i - chg[:delta_needed]
      else
        new_stock = prod.stock.to_i + chg[:delta]
      end

      if new_stock < 0
        errors.add(:base, "No hay stock suficiente para #{prod.titulo}")
        raise ActiveRecord::Rollback
      end

      prod.update_column(:stock, new_stock)
    end
  end

  def self.construir_desde_formulario(venta_params, params, empleado)
    venta = new(venta_params)
    venta.empleado = empleado
    venta.fecha_hora = Time.current

    # Si no se eligió un cliente existente, validar/crear por DNI/nombre/teléfono
    if params.dig(:venta, :cliente_id).blank?
      dni      = params[:dni].to_s.strip
      nombre   = params[:nombre].to_s.strip
      telefono = params[:telefono].to_s.strip

      if dni.blank? || nombre.blank?
        venta.errors.add(:base, "DNI y nombre del cliente son obligatorios.")
        return venta
      end

      unless dni =~ /\A\d{8}\z/
        venta.errors.add(:base, "DNI inválido. Debe contener exactamente 8 dígitos numéricos.")
        return venta
      end

      unless nombre =~ /\A[[:alpha:]\s]{1,20}\z/
        venta.errors.add(:base, "Nombre inválido. Sólo letras y espacios, máximo 20 caracteres.")
        return venta
      end

      if telefono.present? && !(telefono =~ /\A\d{1,20}\z/)
        venta.errors.add(:base, "Teléfono inválido. Sólo números y máximo 20 dígitos.")
        return venta
      end

      cliente = Cliente.find_or_create_by(dni: dni) do |c|
        c.nombre   = nombre
        c.telefono = telefono
      end

      venta.cliente = cliente
    end

    # Validar que haya al menos un detalle
    detalles_attrs = (venta_params[:detalle_ventas_attributes] || {}).values
    if detalles_attrs.empty?
      venta.errors.add(:base, "Debe agregar al menos un producto a la venta")
      return venta
    end

    # Calcular total
    calculated_total = detalles_attrs.sum { |d| d[:cantidad].to_i * d[:precio].to_f }
    venta.total = calculated_total

    venta
  end

  # Guarda la venta y actualiza el stock (usado en create)
  def guardar_y_actualizar_stock
    return false if errors.any? # si ya venía con errores (cliente/detalles), no seguimos

    detalles = detalle_ventas.to_a
    if detalles.empty?
      errors.add(:base, "Debe agregar al menos un producto a la venta")
      return false
    end

    begin
      ActiveRecord::Base.transaction do
        # Validar stock disponible antes de guardar
        detalles.each do |dv|
          producto = Producto.lock.find_by(id: dv.producto_id)
          if producto.nil?
            errors.add(:base, "Producto no encontrado (id=#{dv.producto_id})")
            raise ActiveRecord::Rollback
          end

          if producto.stock.to_i < dv.cantidad.to_i
            errors.add(:base, "No hay stock suficiente para #{producto.titulo}")
            raise ActiveRecord::Rollback
          end
        end

        save! # guarda venta + detalles (nested attributes)

        # Descontar stock
        detalles.each do |dv|
          prod = Producto.lock.find(dv.producto_id)
          new_stock = prod.stock.to_i - dv.cantidad.to_i
          if new_stock < 0
            errors.add(:base, "No hay stock suficiente para #{prod.titulo}")
            raise ActiveRecord::Rollback
          end
          prod.update_column(:stock, new_stock)
        end
      end
      true
    rescue ActiveRecord::RecordInvalid => e
      detail_msg =
        if e.respond_to?(:record) && e.record && e.record.respond_to?(:errors)
          e.record.errors.full_messages.join(", ")
        else
          e.message
        end
      errors.add(:base, "Error al guardar venta o actualizar stock: #{detail_msg}")
      false
    end
  end

  # Actualiza la venta desde el formulario (incluye cliente y stock)
  def actualizar_desde_formulario(venta_params, params)
    # Tomamos los params permitidos de la venta
    incoming = venta_params.to_h

    # --- Procesar campos de cliente enviados como top-level (dni/nombre/telefono) ---
    dni      = params[:dni].to_s.strip
    nombre   = params[:nombre].to_s.strip
    telefono = params[:telefono].to_s.strip

    begin
      if dni.present?
        # Si existe un cliente con ese DNI, asociarlo y actualizar datos si vienen
        cliente_existente = Cliente.find_by(dni: dni)
        if cliente_existente
          cliente_existente.update(nombre: nombre)   if nombre.present?
          cliente_existente.update(telefono: telefono) if telefono.present?
          incoming["cliente_id"] = cliente_existente.id
        else
          # No existe cliente con ese DNI:
          if incoming["cliente_id"].present?
            # si la venta ya apuntaba a un cliente, actualizamos ese cliente con el nuevo DNI/nombre/telefono
            cli = Cliente.find_by(id: incoming["cliente_id"])
            if cli
              cli.update(dni: dni)      if dni.present?
              cli.update(nombre: nombre)   if nombre.present?
              cli.update(telefono: telefono) if telefono.present?
            else
              # crear nuevo cliente
              nuevo = Cliente.create!(dni: dni, nombre: nombre.presence || "", telefono: telefono.presence || "")
              incoming["cliente_id"] = nuevo.id
            end
          else
            # crear nuevo cliente y asociarlo
            nuevo = Cliente.create!(dni: dni, nombre: nombre.presence || "", telefono: telefono.presence || "")
            incoming["cliente_id"] = nuevo.id
          end
        end
      else
        # no se envió dni; si hay cliente_id y vienen nombre/telefono, actualizarlos
        if incoming["cliente_id"].present? && (nombre.present? || telefono.present?)
          cli = Cliente.find_by(id: incoming["cliente_id"])
          if cli
            cli.update(nombre: nombre)   if nombre.present?
            cli.update(telefono: telefono) if telefono.present?
          end
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:base, "No se pudo actualizar/crear cliente: #{e.record.errors.full_messages.join(', ')}")
      return false
    rescue => e
      errors.add(:base, "Error procesando cliente: #{e.message}")
      return false
    end

    # normalizar incoming detalle hash
    detalles_incoming =
      if incoming["detalle_ventas_attributes"].is_a?(Hash)
        incoming["detalle_ventas_attributes"]
      else
        {}
      end

    begin
      ActiveRecord::Base.transaction do
        # calcular cambios de stock (delta positivo = aumento stock, negativo = reducción)
        stock_changes = []

        detalles_incoming.each do |_key, attrs|
          next unless attrs.is_a?(Hash)

          # si marcan para borrado y tiene id, devolver stock del renglón actual
          if attrs["_destroy"].to_s == "1"
            if attrs["id"].present?
              dv = detalle_ventas.find_by(id: attrs["id"].to_i)
              if dv
                stock_changes << { producto_id: dv.producto_id, delta: dv.cantidad.to_i } # repone stock
              end
            end
            next
          end

          producto_id    = attrs["producto_id"].to_i
          cantidad_nueva = attrs["cantidad"].to_i

          if attrs["id"].present?
            dv           = detalle_ventas.find_by(id: attrs["id"].to_i)
            cantidad_ant = dv ? dv.cantidad.to_i : 0
            delta_needed = cantidad_nueva - cantidad_ant
          else
            delta_needed = cantidad_nueva
          end

          # si no hay cambio neto, no toca stock
          next if delta_needed == 0

          prod = Producto.lock.find_by(id: producto_id)
          if prod.nil?
            errors.add(:base, "Producto no encontrado (id=#{producto_id})")
            raise ActiveRecord::Rollback
          end

          # si delta_needed > 0 necesitamos disminuir stock; validamos disponibilidad
          if delta_needed > 0
            if prod.stock.to_i < delta_needed
              errors.add(:base, "No hay stock suficiente para #{prod.titulo} (falta #{delta_needed})")
              raise ActiveRecord::Rollback
            end
            stock_changes << { producto_id: producto_id, delta: -delta_needed } # reducir stock
          else
            # delta_needed < 0 -> aumentar stock (devolver unidades)
            stock_changes << { producto_id: producto_id, delta: -delta_needed.abs } # aumenta stock
          end
        end

        # aplicar update de la venta (raise si falla)
        update!(incoming)

        # aplicar cambios de stock calculados
        stock_changes.each do |chg|
          prod = Producto.lock.find_by(id: chg[:producto_id])
          next unless prod
          new_stock = prod.stock.to_i + chg[:delta]
          if new_stock < 0
            errors.add(:base, "No hay stock suficiente para #{prod.titulo}")
            raise ActiveRecord::Rollback
          end
          prod.update_column(:stock, new_stock)
        end
      end

      true
    rescue ActiveRecord::RecordInvalid => e
      detail_msg =
        if e.respond_to?(:record) && e.record && e.record.respond_to?(:errors)
          e.record.errors.full_messages.join(", ")
        else
          e.message
        end
      errors.add(:base, detail_msg)
      false
    end
  end

  # LÓGICA DE NEGOCIO: Generar el PDF de la factura
  def generar_factura_pdf
    pdf = Prawn::Document.new(page_size: "A4", margin: [ 30, 30, 30, 30 ])

    # Encabezado con logo y datos empresa
    logo_path = Rails.root.join("app/assets/images/ActiveSound.png")
    pdf.image logo_path, width: 60, position: :left if File.exist?(logo_path)

    pdf.bounding_box([ 80, pdf.cursor + 30 ], width: 400) do
      pdf.text "ActiveSound Disquería", size: 18, style: :bold, color: "222222"
      pdf.text "Factura Nº #{id}", size: 14, style: :bold
      pdf.text "Fecha: #{fecha_hora.strftime('%d/%m/%Y %H:%M')}", size: 10
    end
    pdf.move_down 10

    # Datos cliente y vendedor en dos columnas
    pdf.bounding_box([ 0, pdf.cursor ], width: pdf.bounds.width) do
      pdf.bounding_box([ 0, pdf.cursor ], width: pdf.bounds.width / 2 - 10) do
        pdf.text "Cliente", style: :bold, size: 12
        pdf.text "Nombre: #{cliente&.nombre || comprador || 'N/A'}", size: 10
        pdf.text "DNI: #{cliente&.dni || 'N/A'}", size: 10
        pdf.text "Teléfono: #{cliente&.telefono || 'N/A'}", size: 10
      end

      pdf.bounding_box([ pdf.bounds.width / 2 + 10, pdf.cursor ], width: pdf.bounds.width / 2 - 10) do
        pdf.text "Vendedor", style: :bold, size: 12
        pdf.text "#{empleado&.nombre || empleado_id}", size: 10
        pdf.text "Medio de pago: #{pago.present? ? pago.humanize : 'N/A'}", size: 10
      end
    end
    pdf.move_down 20

    # Tabla de productos con estilos
    pdf.text "Detalle de productos", style: :bold, size: 13
    pdf.move_down 5

    data = [ [ "Producto", "Cantidad", "Precio unit.", "Subtotal" ] ]
    total = 0.0

    detalle_ventas.includes(:producto).each do |dv|
      prod = dv.producto
      precio_unit = if dv.precio.present? && dv.precio.to_f > 0
                      dv.precio.to_f
      else
                      (prod&.precio.to_f || 0.0)
      end
      subtotal = dv.cantidad.to_i * precio_unit
      total += subtotal

      data << [
        prod&.titulo || "Producto eliminado",
        dv.cantidad,
        "$#{format('%.2f', precio_unit)}",
        "$#{format('%.2f', subtotal)}"
      ]
    end

    data << [ { content: "Total", colspan: 3, align: :right }, "$#{format('%.2f', total)}" ]

    pdf.table(data, header: true, width: pdf.bounds.width) do
      row(0).background_color = "222222"
      row(0).text_color = "ffffff"
      row(0).font_style = :bold
      row(-1).font_style = :bold
      row(-1).background_color = "eeeeee"
      columns(1..-1).align = :right
      self.cell_style = { size: 10, padding: [ 6, 4, 6, 4 ] }
    end

    pdf.move_down 30
    pdf.text "Gracias por su compra.", align: :center, size: 12, style: :bold
    pdf.text "Documento generado por ActiveSound", align: :center, size: 9, color: "888888"

    pdf.render
  end

  private

  def debe_tener_al_menos_un_detalle
    if detalle_ventas.reject(&:marked_for_destruction?).blank?
      errors.add(:base, "Debe agregar al menos un producto a la venta")
    end
  end

  # Valida los detalle_ventas que NO están marcados para destrucción.
  # Agrega los mensajes de error de cada DetalleVenta al base del modelo Venta.
  def detalles_validos
    detalle_ventas.reject(&:marked_for_destruction?).each_with_index do |dv, idx|
      next if dv.valid?
      dv.errors.full_messages.each do |msg|
        errors.add(:base, "Detalle #{idx + 1}: #{msg}")
      end
    end
  end
end
