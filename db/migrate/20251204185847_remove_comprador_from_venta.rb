class RemoveCompradorFromVenta < ActiveRecord::Migration[8.1]
  def change
    remove_column :venta, :comprador, :string
  end
end
