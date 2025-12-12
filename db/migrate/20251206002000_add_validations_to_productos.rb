class AddValidationsToProductos < ActiveRecord::Migration[8.1]
  def change
    # NOT NULL en campos críticos
    change_column_null :productos, :titulo, false
    change_column_null :productos, :autor, false
    change_column_null :productos, :categoria, false
    change_column_null :productos, :tipo, false
    change_column_null :productos, :estado_fisico, false
    change_column_null :productos, :anio, false
    change_column_null :productos, :precio, false
    change_column_null :productos, :stock, false

    # Check constraints compatibles con SQLite
    add_check_constraint :productos, "precio > 0", name: "precio_positivo"
    add_check_constraint :productos, "stock >= 0", name: "stock_no_negativo"
    add_check_constraint :productos, "anio >= 1900 AND anio <= 2100", name: "anio_valido"
    add_check_constraint :productos, "tipo IN ('vinilo', 'cd')", name: "tipo_valido"
    add_check_constraint :productos, "estado_fisico IN ('nuevo', 'usado')", name: "estado_fisico_valido"
    
    # Índices para mejorar performance
    add_index :productos, :categoria
    add_index :productos, :tipo
    add_index :productos, :estado_fisico
    add_index :productos, :estado
  end
end
