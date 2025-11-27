class Producto < ApplicationRecord

  # === VALIDACIONES ===
  validates :titulo, presence: true
  validates :autor, presence: true
  validates :categoria, presence: true
  validates :tipo, presence: true
 
  # Stock debe ser > 0 y entero
  validates :stock, numericality: { only_integer: true, greater_than: 0 }
 
  # Precio debe ser > 0
  validates :precio, numericality: { greater_than: 0 }

  has_many_attached :imagenes
  has_one_attached :audio_muestra

  before_create :set_default_values
  before_update :set_update_date

  private

  def set_default_values
    self.estado ||= "activo"
    self.fecha_ingreso = Time.current
    self.fecha_modificacion = Time.current
    self.fecha_baja ||= nil
  end

  def set_update_date
    self.fecha_modificacion = Time.current
  end
end
