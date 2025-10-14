class Vehiculo < ApplicationRecord
  belongs_to :usuario

  # Validaciones básicas
  validates :marca, presence: true
  validates :modelo, presence: true
  validates :anio, numericality: { only_integer: true }, allow_nil: true
end
