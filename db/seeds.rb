# Carga de datos de ejemplo para desarrollo y pruebas
# Ejecuta: bin/rails db:seed

puts "==> Creando usuarios"
usuarios_data = [
    { nombre: "Ana García",    email: "ana@example.com" },
    { nombre: "Bruno Pérez",   email: "bruno@example.com" },
    { nombre: "Carla López",   email: "carla@example.com" }
]

# REEMPLAZO: unificar emails (usuarios + vehiculos) y crear usuarios de forma idempotente
vehiculos_data = [
    { marca: "Toyota", modelo: "Corolla", anio: 2020, usuario_email: "ana@example.com" },
    { marca: "Ford", modelo: "Fiesta", anio: 2019, usuario_email: "bruno@example.com" },
    { marca: "Honda", modelo: "Civic", anio: 2021, usuario_email: "carla@example.com" },
    { marca: "Toyota", modelo: "Hilux", anio: 2018, usuario_email: "ana@example.com" }
]

# Construir mapa de nombre por email a partir de usuarios_data
name_by_email = usuarios_data.to_h { |u| [u[:email], u[:nombre]] }

# Asegurar que todos los emails involucrados existan como usuarios
all_emails = (name_by_email.keys + vehiculos_data.map { |v| v[:usuario_email] }).uniq
usuarios = all_emails.map do |email|
  Usuario.find_or_create_by!(email: email) do |u|
    # Generar nombre si no estaba en usuarios_data (e.g., "juan.perez" -> "Juan Perez")
    u.nombre = name_by_email[email] || email.split('@').first.tr('.', ' ').split.map(&:capitalize).join(' ')
  end
end
usuarios_by_email = usuarios.index_by(&:email)

puts "==> Creando vehículos"
vehiculos_data.each do |v|
  usuario = usuarios_by_email.fetch(v[:usuario_email])
  attrs = v.slice(:marca, :modelo, :anio)
  Vehiculo.find_or_create_by!(attrs.merge(usuario: usuario))
end

puts "==> Listo: #{Usuario.count} usuarios y #{Vehiculo.count} vehículos."
