class AddValidationsToCanciones < ActiveRecord::Migration[8.1]
  def change
    change_column_default :canciones, :duracion_segundos, 0
    add_check_constraint :canciones, "duracion_segundos >= 0", name: "duracion_positiva"
    add_check_constraint :canciones, "orden > 0", name: "orden_positivo"
  end
end
