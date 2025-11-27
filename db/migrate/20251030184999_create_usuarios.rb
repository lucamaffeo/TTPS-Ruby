class CreateUsuarios < ActiveRecord::Migration[7.0]
  def change
    create_table :usuarios do |t|
      t.string :nombre, null: false
      t.string :email, null: false
      t.string :dni, null: false
      t.integer :rol, default: 0, null: false

      t.timestamps
    end
    add_index :usuarios, :email, unique: true
    add_index :usuarios, :dni, unique: true
  end
end
