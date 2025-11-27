class DetalleVentum < ApplicationRecord
  belongs_to :venta
  belongs_to :producto
end
