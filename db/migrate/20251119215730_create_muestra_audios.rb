class CreateMuestraAudios < ActiveRecord::Migration[8.1]
  def change
    create_table :muestra_audios do |t|
      t.references :producto, null: false, foreign_key: true

      t.timestamps
    end
  end
end
