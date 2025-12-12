class Venta < ApplicationRecord
  # === RELACIONES ===
  belongs_to :empleado, class_name: "Usuario"
  belongs_to :cliente, optional: true
  # Si borro la venta, se borran sus detalles
  has_many :detalle_ventas, dependent: :destroy
  has_many :productos, through: :detalle_ventas
  # Guarda la venta y sus items en un solo formulario.
  accepts_nested_attributes_for :detalle_ventas, allow_destroy: true

  # === VALIDACIONES ===
  validates :fecha_hora, presence: { message: "no puede estar vacía" }
  validates :empleado, presence: { message: "debe asignarse un vendedor" }
  validates :total, presence: { message: "no puede estar vacío" }, numericality: { greater_than_or_equal_to: 0, message: "debe ser >= 0" }
  validates :pago, presence: { message: "debe seleccionar un medio de pago" }, inclusion: { in: %w[efectivo transferencia debito], message: "medio de pago inválido" }
  validate  :debe_tener_al_menos_un_detalle
  # validates_associated :detalle_ventas
  # Validamos manualmente los detalles, ignorando los marcados para borrado
  validate :detalles_validos

  scope :activas, -> { where(cancelada: false) }

  # Indica si la venta ya fue cancelada
  def cancelada?
    !!self.cancelada
  end

  # Cancela la venta: marca cancelada, setea fecha_cancelacion y repone stock.
  # Operación en transacción para evitar inconsistencias.
  def cancelar!(motivo: nil)
    return false if cancelada?

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
