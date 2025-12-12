class AddValidationsToVenta < ActiveRecord::Migration[6.0]
  def change
    change_column_null :venta, :fecha_hora, false
    change_column_null :venta, :total, false
    add_check_constraint :venta, "total >= 0", name: "total_no_negativo"
  end
end
