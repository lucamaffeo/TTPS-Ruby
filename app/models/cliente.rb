class Cliente < ApplicationRecord
  # Un cliente puede haber realizado ventas
  has_many :ventas

  validates :dni, presence: true, uniqueness: true
  validates :nombre, presence: true
end
