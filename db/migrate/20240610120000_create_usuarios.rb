class CreateUsuarios < ActiveRecord::Migration[8.0]
  def change
    create_table :usuarios do |t|
      t.string :nombre
      t.string :email

      t.timestamps
    end
  end
end
