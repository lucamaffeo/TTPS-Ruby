class CreateImagenProductos < ActiveRecord::Migration[8.1]
  def change
    create_table :imagen_productos do |t|
      t.references :producto, null: false, foreign_key: true
      t.boolean :es_portada

      t.timestamps
    end
  end
end
