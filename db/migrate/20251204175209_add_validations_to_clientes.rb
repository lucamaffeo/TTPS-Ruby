class AddValidationsToClientes < ActiveRecord::Migration[8.1]
  def change
    # NOT NULL en campos obligatorios
    change_column_null :clientes, :nombre, false
    change_column_null :clientes, :dni, false
    
    # DNI único
    add_index :clientes, :dni, unique: true
    
    # Check constraint simplificado para SQLite: solo validar longitud
    # La validación de que sean números se hace en el modelo
    add_check_constraint :clientes, "LENGTH(dni) >= 7 AND LENGTH(dni) <= 8", name: "dni_longitud_valida"
  end
end
