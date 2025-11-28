class Producto < ApplicationRecord
  # === RELACIONES ===
  has_many :detalle_ventas
  has_many :ventas, through: :detalle_ventas
  # === VALIDACIONES ===
  validates :titulo, presence: true
  validates :autor, presence: true
  validates :categoria, presence: true
  validates :tipo, presence: true
  validates :anio, numericality: { only_integer: true, greater_than: 1900, less_than_or_equal_to: Time.current.year }, allow_nil: true
 
  # Stock debe ser > 0 y entero
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
 
  # Precio debe ser > 0
  validates :precio, numericality: { greater_than: 0 }

  has_many_attached :imagenes
  has_one_attached :audio_muestra

  before_create :set_default_values
  before_update :set_update_date

  validate :stock_por_estado_fisico

  private

  def set_default_values
    self.estado = "activo" if self.estado.blank?
    self.fecha_ingreso = Time.current
    self.fecha_modificacion = Time.current
    self.fecha_baja ||= nil
  end

  def set_update_date
    self.fecha_modificacion = Time.current
    # No modificar self.estado aquí
  end

  def stock_por_estado_fisico
    if estado_fisico == "usado"
      errors.add(:stock, "debe ser 1 para productos usados") unless stock == 1
    elsif estado_fisico == "nuevo"
      errors.add(:stock, "debe ser mayor a 0 para productos nuevos") unless stock.present? && stock > 0
    end
  end
end
