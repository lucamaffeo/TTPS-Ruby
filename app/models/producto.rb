class Producto < ApplicationRecord
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
