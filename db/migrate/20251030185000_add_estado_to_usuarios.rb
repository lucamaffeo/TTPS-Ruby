class AddEstadoToUsuarios < ActiveRecord::Migration[7.0]
  def change
    add_column :usuarios, :estado, :integer, default: 0, null: false
    add_index :usuarios, :estado
  end
end
