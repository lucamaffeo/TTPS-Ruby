class DetalleVenta < ApplicationRecord
  belongs_to :venta
  belongs_to :producto

  validates :producto, presence: true
  validates :cantidad, numericality: { greater_than: 0, only_integer: true }
  validates :precio, numericality: { greater_than: 0 }
end
