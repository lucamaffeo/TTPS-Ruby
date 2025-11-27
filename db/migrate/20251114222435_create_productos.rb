class CreateProductos < ActiveRecord::Migration[8.1]
  def change
    create_table :productos do |t|
      t.string :titulo
      t.text :descripcion
      t.string :autor
      t.decimal :precio
      t.integer :stock
      t.string :categoria
      t.string :tipo
      t.string :estado
      t.date :fecha_ingreso
      t.date :fecha_modificacion
      t.date :fecha_baja

      t.timestamps
    end
  end
end
