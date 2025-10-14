class CreateVehiculos < ActiveRecord::Migration[6.0]
  def change
    create_table :vehiculos do |t|
      t.references :usuario, null: false, foreign_key: true
      t.string :marca
      t.string :modelo
      t.integer :anio

      t.timestamps
    end
  end
end
