class AddClienteToVentas < ActiveRecord::Migration[8.1]
  def change
    add_reference :venta, :cliente, null: true, foreign_key: true
  end
end
