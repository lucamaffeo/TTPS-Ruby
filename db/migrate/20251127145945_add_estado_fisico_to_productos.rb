class AddEstadoFisicoToProductos < ActiveRecord::Migration[8.1]
  def change
    add_column :productos, :estado_fisico, :string
  end
end
