class VentaController < ApplicationController
  before_action :authenticate_usuario!, only: %i[new create edit update destroy]
  before_action :set_venta, only: %i[ show edit update destroy ]

  require "prawn"
  require "prawn/table"

  # # GET /venta or /venta.json
  def index
    # incluimos cliente y empleado para evitar N+1; orden por fecha
    @ventas = Venta.left_outer_joins(:cliente).includes(:cliente, :empleado).order(fecha_hora: :desc)

    # 1. Búsqueda por Cliente (nombre en tabla clientes)
    if params[:q].present?
      q = params[:q].to_s.downcase
      # usamos LOWER sobre clientes.nombre; left join permite ventas sin cliente
      @ventas = @ventas.where("LOWER(clientes.nombre) LIKE ?", "%#{q}%")
    end

    # 2. Filtro por Empleado (Usuario)
    if params[:empleado_id].present?
      @ventas = @ventas.where(empleado_id: params[:empleado_id])
    end

    # 3. Filtro por Rango de Fechas
    if params[:fecha_inicio].present?
      fecha_inicio = Date.parse(params[:fecha_inicio]) rescue nil
      @ventas = @ventas.where("fecha_hora >= ?", fecha_inicio.beginning_of_day) if fecha_inicio
    end

    if params[:fecha_fin].present?
      fecha_fin = Date.parse(params[:fecha_fin]) rescue nil
      @ventas = @ventas.where("fecha_hora <= ?", fecha_fin.end_of_day) if fecha_fin
    end

    # Paginación
    @ventas = @ventas.page(params[:page]).per(10)
  end


  # Aca lo que hace es mostrar una venta especifica.
  def show
    respond_to do |format|
      format.html
      format.pdf do
        pdf = Prawn::Document.new(page_size: "A4", margin: [ 30, 30, 30, 30 ])

        # Encabezado con logo y datos empresa
        pdf.image Rails.root.join("app/assets/images/ActiveSound.png"), width: 60, position: :left if File.exist?(Rails.root.join("app/assets/images/ActiveSound.png"))
        pdf.bounding_box([ 80, pdf.cursor + 30 ], width: 400) do
          pdf.text "ActiveSound Disquería", size: 18, style: :bold, color: "222222"
          pdf.text "Factura Nº #{@venta.id}", size: 14, style: :bold
          pdf.text "Fecha: #{@venta.fecha_hora.strftime('%d/%m/%Y %H:%M')}", size: 10
        end
        pdf.move_down 10

        # Datos cliente y vendedor en dos columnas
        pdf.bounding_box([ 0, pdf.cursor ], width: pdf.bounds.width) do
          pdf.bounding_box([ 0, pdf.cursor ], width: pdf.bounds.width / 2 - 10) do
            pdf.text "Cliente", style: :bold, size: 12
            pdf.text "Nombre: #{@venta.cliente&.nombre || @venta.comprador || 'N/A'}", size: 10
            pdf.text "DNI: #{@venta.cliente&.dni || 'N/A'}", size: 10
            pdf.text "Teléfono: #{@venta.cliente&.telefono || 'N/A'}", size: 10
          end
          pdf.bounding_box([ pdf.bounds.width / 2 + 10, pdf.cursor ], width: pdf.bounds.width / 2 - 10) do
            pdf.text "Vendedor", style: :bold, size: 12
            pdf.text "#{@venta.empleado&.nombre || @venta.empleado_id}", size: 10
            pdf.text "Medio de pago: #{@venta.pago.present? ? @venta.pago.humanize : 'N/A'}", size: 10
          end
        end
        pdf.move_down 20

        # Tabla de productos con estilos
        pdf.text "Detalle de productos", style: :bold, size: 13
        pdf.move_down 5
        data = [ [ "Producto", "Cantidad", "Precio unit.", "Subtotal" ] ]
        total = 0.0
        @venta.detalle_ventas.includes(:producto).each do |dv|
          prod = dv.producto
          precio_unit = (dv.precio.present? && dv.precio.to_f > 0) ? dv.precio.to_f : (prod&.precio.to_f || 0.0)
          subtotal = dv.cantidad.to_i * precio_unit
          total += subtotal
          data << [
            prod&.titulo || "Producto eliminado",
            dv.cantidad,
            "$#{'%.2f' % precio_unit}",
            "$#{'%.2f' % subtotal}"
          ]
        end
        data << [ { content: "Total", colspan: 3, align: :right }, "$#{'%.2f' % total}" ]
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

        send_data pdf.render,
                  filename: "factura-#{@venta.id}.pdf",
                  type: "application/pdf",
                  disposition: "attachment"
      end
    end
  end

  def edit
    @venta = Venta.find(params[:id])
    @venta.detalle_ventas.build if @venta.detalle_ventas.empty?
  end

  # Aca lo que hace es inicializar una nueva venta y cargar los productos para el formulario.
  def new
    @venta = Venta.new
    @venta.detalle_ventas.build
    @productos = Producto.order(:titulo).limit(200)
    @venta.empleado = current_usuario
  end
  # # GET /venta/1/edit
  # def edit
  # end

  # Aca lo que hace es crear una nueva venta con los parametros que vienen del formulario.
  def create
    # Validar datos del cliente cuando no se seleccionó uno existente
    if params[:venta][:cliente_id].blank?
      dni     = params[:dni].to_s.strip
      nombre  = params[:nombre].to_s.strip
      telefono = params[:telefono].to_s.strip

      @venta = Venta.new(venta_params)
      @venta.empleado = current_usuario
      @venta.fecha_hora = Time.now

      if dni.blank? || nombre.blank?
        @venta.errors.add(:base, "DNI y nombre del cliente son obligatorios.")
        @productos = Producto.order(:titulo).limit(200)
        return render :new, status: :unprocessable_entity
      end

      # DNI: exactamente 8 dígitos numéricos
      unless dni =~ /\A\d{8}\z/
        @venta.errors.add(:base, "DNI inválido. Debe contener exactamente 8 dígitos numéricos.")
        @productos = Producto.order(:titulo).limit(200)
        return render :new, status: :unprocessable_entity
      end

      # Nombre: sólo letras y espacios, máximo 20 caracteres
      unless nombre =~ /\A[[:alpha:]\s]{1,20}\z/
        @venta.errors.add(:base, "Nombre inválido. Sólo letras y espacios, máximo 20 caracteres.")
        @productos = Producto.order(:titulo).limit(200)
        return render :new, status: :unprocessable_entity
      end

      # Teléfono: opcional, pero si viene debe ser solo números y hasta 20 caracteres
      if telefono.present? && !(telefono =~ /\A\d{1,20}\z/)
        @venta.errors.add(:base, "Teléfono inválido. Sólo números y máximo 20 dígitos.")
        @productos = Producto.order(:titulo).limit(200)
        return render :new, status: :unprocessable_entity
      end

      cliente = Cliente.find_or_create_by(dni: dni) do |c|
        c.nombre   = nombre
        c.telefono = telefono
      end

      params[:venta][:cliente_id] = cliente.id
    end

    # construir la venta normalmente (si arriba ya se creó @venta, se recrea pero con cliente_id seteado)
    @venta = Venta.new(venta_params)
    @venta.empleado = current_usuario
    @venta.fecha_hora = Time.now

    detalles_attrs = (venta_params[:detalle_ventas_attributes] || {}).values
    if detalles_attrs.empty?
      @venta.errors.add(:base, "Debe agregar al menos un producto a la venta")
      @productos = Producto.order(:titulo).limit(200)
      render :new, status: :unprocessable_entity and return
    end

    calculated_total = detalles_attrs.sum { |d| d[:cantidad].to_i * d[:precio].to_f }
    @venta.total = calculated_total

    ActiveRecord::Base.transaction do
      detalles_attrs.each do |d|
        producto = Producto.lock.find_by(id: d[:producto_id])
        if producto.nil?
          @venta.errors.add(:base, "Producto no encontrado (id=#{d[:producto_id]})")
          raise ActiveRecord::Rollback
        end

        # Rechazar si la cantidad solicitada excede el stock disponible
        if producto.stock.to_i < d[:cantidad].to_i
          @venta.errors.add(:base, "No hay stock suficiente para #{producto.titulo}")
          raise ActiveRecord::Rollback
        end
      end

      if @venta.save
        begin
          @venta.detalle_ventas.each do |dv|
            prod = Producto.lock.find(dv.producto_id)
            # Ajustar stock usando update_column (evita validaciones que impidan poner 0)
            new_stock = prod.stock.to_i - dv.cantidad.to_i
            if new_stock < 0
              @venta.errors.add(:base, "No hay stock suficiente para #{prod.titulo}")
              raise ActiveRecord::Rollback
            end
            prod.update_column(:stock, new_stock)
          end
        rescue ActiveRecord::RecordInvalid => e
          detail_msg = (e.respond_to?(:record) && e.record && e.record.respond_to?(:errors)) ? e.record.errors.full_messages.join(", ") : e.message
          @venta.errors.add(:base, "Error al actualizar stock: #{detail_msg}")
          raise ActiveRecord::Rollback
        end
        redirect_to venta_path(@venta), notice: "Venta creada correctamente." and return
      else
        raise ActiveRecord::Rollback
      end
    end

    @productos = Producto.order(:titulo).limit(200)
    render :new, status: :unprocessable_entity
  end

  # Aca lo que hace es actualizar una venta especifica.
  def update
    # Tomamos los params permitidos de la venta
    incoming = venta_params.to_h

    # --- Procesar campos de cliente enviados como top-level (dni/nombre/telefono) ---
    dni = params[:dni].to_s.strip
    nombre = params[:nombre].to_s.strip
    telefono = params[:telefono].to_s.strip

    begin
      if dni.present?
        # Si existe un cliente con ese DNI, asociarlo y actualizar datos si vienen
        cliente_existente = Cliente.find_by(dni: dni)
        if cliente_existente
          cliente_existente.update(nombre: nombre) if nombre.present?
          cliente_existente.update(telefono: telefono) if telefono.present?
          incoming["cliente_id"] = cliente_existente.id
        else
          # No existe cliente con ese DNI:
          if incoming["cliente_id"].present?
            # si la venta ya apuntaba a un cliente, actualizamos ese cliente con el nuevo DNI/nombre/telefono
            cli = Cliente.find_by(id: incoming["cliente_id"])
            if cli
              cli.update(dni: dni) if dni.present?
              cli.update(nombre: nombre) if nombre.present?
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
            cli.update(nombre: nombre) if nombre.present?
            cli.update(telefono: telefono) if telefono.present?
          end
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      @venta.errors.add(:base, "No se pudo actualizar/crear cliente: #{e.record.errors.full_messages.join(', ')}")
      @productos = Producto.order(:titulo)
      return render :edit, status: :unprocessable_entity
    rescue => e
      @venta.errors.add(:base, "Error procesando cliente: #{e.message}")
      @productos = Producto.order(:titulo)
      return render :edit, status: :unprocessable_entity
    end

    # normalizar incoming detalle hash
    detalles_incoming = incoming["detalle_ventas_attributes"].is_a?(Hash) ? incoming["detalle_ventas_attributes"] : {}

    ActiveRecord::Base.transaction do
      # calcular cambios de stock (delta positivo = aumento stock, negativo = reducción)
      stock_changes = []

      detalles_incoming.each do |_key, attrs|
        next unless attrs.is_a?(Hash)
        # si marcan para borrado y tiene id, devolver stock del renglón actual
        if attrs["_destroy"].to_s == "1"
          if attrs["id"].present?
            dv = @venta.detalle_ventas.find_by(id: attrs["id"].to_i)
            if dv
              stock_changes << { producto_id: dv.producto_id, delta: dv.cantidad.to_i } # repone stock
            end
          end
          next
        end

        producto_id = attrs["producto_id"].to_i
        cantidad_nueva = attrs["cantidad"].to_i

        if attrs["id"].present?
          dv = @venta.detalle_ventas.find_by(id: attrs["id"].to_i)
          cantidad_ant = dv ? dv.cantidad.to_i : 0
          delta_needed = cantidad_nueva - cantidad_ant
        else
          delta_needed = cantidad_nueva
        end

        # si no hay cambio neto, no toca stock
        next if delta_needed == 0

        prod = Producto.lock.find_by(id: producto_id)
        if prod.nil?
          @venta.errors.add(:base, "Producto no encontrado (id=#{producto_id})")
          raise ActiveRecord::Rollback
        end

        # si delta_needed > 0 necesitamos disminuir stock; validamos disponibilidad
        if delta_needed > 0
          if prod.stock.to_i < delta_needed
            @venta.errors.add(:base, "No hay stock suficiente para #{prod.titulo} (falta #{delta_needed})")
            raise ActiveRecord::Rollback
          end
          stock_changes << { producto_id: producto_id, delta: -delta_needed } # reducir stock
        else
          # delta_needed < 0 -> aumentar stock (devolver unidades)
          stock_changes << { producto_id: producto_id, delta: -delta_needed.abs } # aumenta stock
        end
      end

      # aplicar update de la venta (raise si falla)
      @venta.update!(incoming)

      # aplicar cambios de stock calculados
      stock_changes.each do |chg|
        prod = Producto.lock.find_by(id: chg[:producto_id])
        next unless prod
        new_stock = prod.stock.to_i + chg[:delta]
        if new_stock < 0
          @venta.errors.add(:base, "No hay stock suficiente para #{prod.titulo}")
          raise ActiveRecord::Rollback
        end
        prod.update_column(:stock, new_stock)
      end

      redirect_to venta_path(@venta), notice: "Venta actualizada correctamente." and return
    end
  rescue ActiveRecord::RecordInvalid => e
    detail_msg = (e.respond_to?(:record) && e.record && e.record.respond_to?(:errors)) ? e.record.errors.full_messages.join(", ") : e.message
    @venta.errors.add(:base, detail_msg)
    @productos = Producto.order(:titulo)
    render :edit, status: :unprocessable_entity
  end
  # Elimina (lógicamente) una venta especifica.
  def destroy
    if @venta.cancelada?
      redirect_to({ controller: "venta", action: :index }, alert: "La venta ya estaba cancelada.") and return
    end

    begin
      @venta.cancelar!
      redirect_to({ controller: "venta", action: :index }, notice: "Venta cancelada correctamente. Se repuso el stock.")
    rescue => e
      logger.error("Error cancelando venta #{@venta.id}: #{e.message}")
      redirect_to({ controller: "venta", action: :index }, alert: "No se pudo cancelar la venta: #{e.message}")
    end
  end

  # Aca lo que hace es buscar la venta por el id que viene en los parametros de la url.
  def set_venta
    @venta = Venta.find(params[:id])
  end

  # venta_params lo que hace es permitir los parametros para crear o actualizar una venta, vienen del formulario.
  def venta_params
    params.require(:venta).permit(
      :total,
      :pago,               # <-- permitir medio de pago
      :cliente_id,
      :empleado_id,
      detalle_ventas_attributes: [ :id, :producto_id, :cantidad, :precio, :_destroy ]
    )
  end

  private
  # Filtra los atributos de detalle_ventas: mantiene elementos nuevos (sin id) y
  # solo aquellos con id que efectivamente pertenecen a @venta.
  def sanitize_detalle_ventas_attributes(hash_attrs)
    hash_attrs.select do |key, det_attrs|
      next true unless det_attrs.is_a?(Hash)
      if det_attrs["id"].present?
        DetalleVenta.exists?(id: det_attrs["id"].to_i, venta_id: @venta.id)
      else
        true
      end
    end
  end
end
