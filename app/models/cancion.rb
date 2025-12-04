class Cancion < ApplicationRecord
  self.table_name = "canciones"

  belongs_to :producto

  validates :nombre, presence: true
  validates :duracion_segundos, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :orden, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  def duracion_hhmmss
    s = duracion_segundos.to_i
    m = (s / 60)
    sec = (s % 60)
    s > 0 ? format("%02d:%02d", m, sec) : "—"
  end
end
