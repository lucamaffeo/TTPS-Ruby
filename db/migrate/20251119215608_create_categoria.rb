class CreateCategoria < ActiveRecord::Migration[8.1]
  def change
    create_table :categoria do |t|
      t.string :nombre

      t.timestamps
    end
  end
end
