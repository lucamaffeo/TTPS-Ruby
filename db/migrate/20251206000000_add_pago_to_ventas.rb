class AddPagoToVentas < ActiveRecord::Migration[6.0]
  def change
    add_column :venta, :pago, :string, default: 'efectivo', null: false
  end
end
