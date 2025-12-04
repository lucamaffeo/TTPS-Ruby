class CreateCanciones < ActiveRecord::Migration[8.1]
  def change
    create_table :canciones do |t|
      t.references :producto, null: false, foreign_key: true
      t.string :nombre, null: false
      t.integer :duracion_segundos, null: false, default: 0
      t.integer :orden # posición en el disco (track number)
      t.string :autor # opcional si difiere del autor del producto

      t.timestamps
    end
    add_index :canciones, [:producto_id, :orden]
  end
end
