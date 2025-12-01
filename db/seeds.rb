# Carga de datos de ejemplo para desarrollo y pruebas
# Ejecuta: bin/rails db:seed

puts "==> Reseteando datos de usuarios (solo desarrollo)"
if Rails.env.development?
  Vehiculo.delete_all if defined?(Vehiculo)
  Usuario.delete_all
end

puts "==> Creando usuarios"
usuarios = [
  { nombre: "Luca",    email: "admin@example.com",    dni: "10000001", rol: 2 }, # administrador
  { nombre: "Ale",  email: "gerente@example.com",  dni: "10000002", rol: 1 }, # gerente
  { nombre: "Franco", email: "empleado@example.com", dni: "10000003", rol: 0 }  # empleado
]

usuarios.each do |attrs|
  u = Usuario.find_or_initialize_by(email: attrs[:email])
  u.assign_attributes(
    nombre: attrs[:nombre],
    dni: attrs[:dni],
    rol: attrs[:rol],
    password: "password",
    password_confirmation: "password"
  )
  u.save!
end

puts "==> Listo: #{Usuario.count} usuarios creados."
