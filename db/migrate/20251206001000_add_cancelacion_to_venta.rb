class AddCancelacionToVenta < ActiveRecord::Migration[6.0]
  def change
    add_column :venta, :cancelada, :boolean, default: false, null: false
    add_column :venta, :fecha_cancelacion, :datetime
    add_index :venta, :cancelada
  end
end
