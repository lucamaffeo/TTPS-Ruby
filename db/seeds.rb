# Carga de datos de ejemplo para desarrollo y pruebas
# Ejecuta: bin/rails db:seed

puts "==> Creando usuarios"
usuarios_data = [
    { nombre: "Ana García",    email: "ana@example.com" },
    { nombre: "Bruno Pérez",   email: "bruno@example.com" },
    { nombre: "Carla López",   email: "carla@example.com" }
]

usuarios = usuarios_data.map do |attrs|
    Usuario.find_or_create_by!(email: attrs[:email]) do |u|
        u.nombre = attrs[:nombre]
    end
end

usuario_by_email = usuarios.index_by(&:email)

puts "==> Creando vehículos"
vehiculos_data = [
    { usuario_email: "ana@example.com",   marca: "Toyota",   modelo: "Corolla",  anio: 2020 },
    { usuario_email: "bruno@example.com", marca: "Ford",     modelo: "Fiesta",   anio: 2018 },
    { usuario_email: "carla@example.com", marca: "Honda",    modelo: "Civic",    anio: 2022 },
    { usuario_email: "ana@example.com",   marca: "Renault",  modelo: "Clio",     anio: 2016 }
]

vehiculos_data.each do |attrs|
    user = usuario_by_email.fetch(attrs[:usuario_email])
    Vehiculo.find_or_create_by!(
        usuario: user,
        marca: attrs[:marca],
        modelo: attrs[:modelo],
        anio: attrs[:anio]
    )
end

puts "==> Listo: #{Usuario.count} usuarios y #{Vehiculo.count} vehículos."


# Create some default users
usuarios = [
    { nombre: "Juan Perez", email: "juan.perez@example.com" },
]
vehiculos = [
    { marca: "Toyota", modelo: "Corolla", anio: 2020, usuario_email: "juan.perez@example.com" }
]

vehiculos.each do |vehiculo_attrs|
    Vehiculo.find_or_create_by!(vehiculo_attrs)
end
usuarios.each do |usuario_attrs|
    Usuario.find_or_create_by!(usuario_attrs)
end
    