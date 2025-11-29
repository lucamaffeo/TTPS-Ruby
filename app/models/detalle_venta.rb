class DetalleVenta < ApplicationRecord
  belongs_to :venta
  belongs_to :producto

  validates :cantidad, numericality: { greater_than: 0, only_integer: true }
  validates :precio, numericality: { greater_than_or_equal_to: 0 }
end
