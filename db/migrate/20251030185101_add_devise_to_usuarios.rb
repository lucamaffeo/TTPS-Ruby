# frozen_string_literal: true

class AddDeviseToUsuarios < ActiveRecord::Migration[8.1]
  def self.up
    # Agregar columnas solo si no existen (evita "duplicate column name")
    add_column :usuarios, :email,              :string,  null: false, default: "" unless column_exists?(:usuarios, :email)
    add_column :usuarios, :encrypted_password, :string,  null: false, default: "" unless column_exists?(:usuarios, :encrypted_password)

    add_column :usuarios, :reset_password_token,    :string   unless column_exists?(:usuarios, :reset_password_token)
    add_column :usuarios, :reset_password_sent_at,  :datetime unless column_exists?(:usuarios, :reset_password_sent_at)
    add_column :usuarios, :remember_created_at,     :datetime unless column_exists?(:usuarios, :remember_created_at)

    add_column :usuarios, :rol, :integer, null: false, default: 0 unless column_exists?(:usuarios, :rol)

    # Perfil
    add_column :usuarios, :nombre, :string unless column_exists?(:usuarios, :nombre)
    add_column :usuarios, :dni,    :string unless column_exists?(:usuarios, :dni)

    # Índices solo si faltan
    add_index :usuarios, :email,                unique: true unless index_exists?(:usuarios, :email, unique: true)
    add_index :usuarios, :reset_password_token, unique: true if column_exists?(:usuarios, :reset_password_token) && !index_exists?(:usuarios, :reset_password_token, unique: true)
    add_index :usuarios, :rol unless index_exists?(:usuarios, :rol)

    # Constraint del rol solo si falta
    add_check_constraint :usuarios, "rol IN (0,1,2)", name: "usuarios_rol_in_range", if_not_exists: true if column_exists?(:usuarios, :rol)

    # Backfill de nombre/dni sin definir clases dentro del método
    if column_exists?(:usuarios, :nombre) && column_exists?(:usuarios, :dni)
      say_with_time "Backfilling nombre y dni para usuarios existentes" do
        rows = select_all("SELECT id, email, nombre, dni FROM usuarios")
        rows.each do |u|
          nuevo_nombre = u["nombre"].to_s.strip
          nuevo_dni    = u["dni"].to_s.strip
          nuevo_nombre = (u["email"].to_s.split("@").first.presence || "usuario#{u["id"]}") if nuevo_nombre.empty?
          nuevo_dni    = "PEND-#{u["id"]}" if nuevo_dni.empty?

          execute <<~SQL.squish
            UPDATE usuarios
            SET nombre = #{connection.quote(nuevo_nombre)},
                dni    = #{connection.quote(nuevo_dni)}
            WHERE id = #{u["id"]}
          SQL
        end
      end

      change_column_null :usuarios, :nombre, false
      change_column_null :usuarios, :dni,    false
      add_index :usuarios, :dni, unique: true unless index_exists?(:usuarios, :dni, unique: true)
    end
  end

  def self.down
    # By default, we don't want to make any assumption about how to roll back a migration when your
    # model already existed. Please edit below which fields you would like to remove in this migration.
    raise ActiveRecord::IrreversibleMigration
  end
end
