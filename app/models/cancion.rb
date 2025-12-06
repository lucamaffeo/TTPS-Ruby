class Cancion < ApplicationRecord
  # Se setea el nombre.
  self.table_name = "canciones"

  # Una canción no existe sola, pertenece a un producto
  belongs_to :producto

  # No puede estar vacío.
  validates :nombre, presence: true

  validates :duracion_segundos, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :orden, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  # Este método convierte los segundos (ej: 125) a este formato "02:05".
  def duracion_hhmmss
    s = duracion_segundos.to_i
    m = (s / 60)
    sec = (s % 60)
    s > 0 ? format("%02d:%02d", m, sec) : "—"
  end
end
