class Venta < ApplicationRecord
  # === RELACIONES ===
  belongs_to :empleado, class_name: "Usuario"
  belongs_to :cliente, optional: true
  has_many :detalle_ventas, dependent: :destroy
  has_many :productos, through: :detalle_ventas

  accepts_nested_attributes_for :detalle_ventas, allow_destroy: true

  # === VALIDACIONES ===
  validates :fecha_hora, presence: true
  validates :empleado, presence: true
  validates :total, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :pago, inclusion: { in: %w[efectivo transferencia debito] }, presence: true
  validate  :debe_tener_al_menos_un_detalle
  # validates_associated :detalle_ventas
  # Validamos manualmente los detalles, ignorando los marcados para borrado
  validate :detalles_validos

  # attribute :cancelada, :boolean, default: false

  # before_create :validar_stock
  # after_create :descontar_stock
  # after_update :revertir_stock, if: :cancelada?

  # scope :activas, -> { where(cancelada: false) }
  # scope :por_empleado, ->(empleado_id) { where(empleado_id: empleado_id) }
  # scope :por_fecha, ->(fecha) { where(fecha_hora: fecha.beginning_of_day..fecha.end_of_day) }

  # # private
  # # # Lo que hace aca es
  # # def validar_stock
  #   detalle_ventas.each do |dv|
  #     if dv.cantidad > dv.producto.stock
  #       errors.add(:base, "No hay stock suficiente para #{dv.producto.nombre}")
  #       throw(:abort)
  #     end
  #   end
  # end

  # # ➖
  # def descontar_stock
  #   detalle_ventas.each do |dv|
  #     dv.producto.update!(stock: dv.producto.stock - dv.cantidad)
  #   end
  # end

  # # ➕
  # def revertir_stock
  #   detalle_ventas.each do |dv|
  #     dv.producto.update!(stock: dv.producto.stock + dv.cantidad)
  #   end
  # end

  # scope para ventas activas (no canceladas)
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
        next unless prod
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
