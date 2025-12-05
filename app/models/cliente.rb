class Cliente < ApplicationRecord

  has_many :ventas

  validates :dni, presence: true, uniqueness: true
  validates :nombre, presence: true
end
