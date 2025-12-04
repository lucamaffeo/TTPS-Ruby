class CreateClientes < ActiveRecord::Migration[8.1]
  def change
    create_table :clientes do |t|
      t.string :nombre
      t.string :dni
      t.string :telefono

      t.timestamps
    end
  end
end
