class RenameFormatoToTipoInProductos < ActiveRecord::Migration[8.1]
  def change
    rename_column :productos, :formato, :tipo
  end
end
