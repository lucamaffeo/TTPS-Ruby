class Venta < ApplicationRecord
  # === RELACIONES ===
  belongs_to :empleado, class_name: "Usuario"
  belongs_to :cliente, optional: true
  has_many :detalle_ventas, dependent: :destroy
  has_many :productos, through: :detalle_ventas

  accepts_nested_attributes_for :detalle_ventas, allow_destroy: true

  # === VALIDACIONES ===
  validates :fecha_hora, presence: { message: "no puede estar vacía" }
  validates :empleado, presence: { message: "debe asignarse un vendedor" }
  validates :cliente, presence: { message: "debe asignarse un cliente" }
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
