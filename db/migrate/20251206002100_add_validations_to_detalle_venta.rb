class AddValidationsToDetalleVenta < ActiveRecord::Migration[8.1]
  def change
    # NOT NULL
    change_column_null :detalle_venta, :cantidad, false
    change_column_null :detalle_venta, :precio, false
    
    # Check constraints
    add_check_constraint :detalle_venta, "cantidad > 0", name: "cantidad_positiva"
    add_check_constraint :detalle_venta, "precio > 0", name: "precio_unitario_positivo"
  end
end
