class CreateVenta < ActiveRecord::Migration[8.1]
  def change
    create_table :venta do |t|
      t.datetime :fecha_hora
      t.decimal :total
      t.string :comprador
      t.references :usuario, null: false, foreign_key: true

      t.timestamps
    end
  end
end
