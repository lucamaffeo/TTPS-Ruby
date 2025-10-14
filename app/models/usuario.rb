class Usuario < ApplicationRecord
  has_many :vehiculos, dependent: :destroy
  accepts_nested_attributes_for :vehiculos, allow_destroy: true
  # Aquí podrías agregar validaciones, relaciones, etc.
end
