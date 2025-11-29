class FixForeignKeyEmpleadoInVenta < ActiveRecord::Migration[8.1]
  def change
    # La tabla está mal nombrada como "venta" en singular
    table_name = table_exists?(:venta) ? :venta : :ventas

    # Eliminar FK vieja que apunta a "empleados" si existe
    if foreign_key_exists?(table_name, column: :empleado_id)
      remove_foreign_key table_name, column: :empleado_id
    end

    # Agregar FK correcta a usuarios
    add_foreign_key table_name, :usuarios, column: :empleado_id
  end
end
