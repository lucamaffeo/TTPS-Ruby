class Venta < ApplicationRecord
  # === RELACIONES ===
  belongs_to :empleado, class_name: "Usuario"
  has_many :detalle_ventas, dependent: :destroy
  has_many :productos, through: :detalle_ventas

  accepts_nested_attributes_for :detalle_ventas, allow_destroy: true

  # === VALIDACIONES ===
  validates :fecha_hora, presence: true
  validates :empleado, presence: true
  validates :comprador, presence: { message: "no puede estar vacío" }
  validates :total, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate  :debe_tener_al_menos_un_detalle
  validates_associated :detalle_ventas

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

  private

  def debe_tener_al_menos_un_detalle
    if detalle_ventas.reject(&:marked_for_destruction?).blank?
      errors.add(:base, "Debe agregar al menos un producto a la venta")
    end
  end
end