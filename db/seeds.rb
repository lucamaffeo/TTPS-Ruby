# SEED BÁSICO: usuarios, productos, canciones y ventas (con imágenes/audio)
require "faker"
require "stringio"

puts "==> Reseteando datos"
Usuario.delete_all
Cliente.delete_all
Producto.delete_all
Cancion.delete_all
Venta.delete_all
DetalleVenta.delete_all

puts "==> Creando usuarios"
usuarios = [
  { nombre: "Luca",    email: "admin@example.com",    dni: "10000001", rol: 2 },
  { nombre: "Ale",     email: "gerente@example.com",  dni: "10000002", rol: 1 },
  { nombre: "Juan",    email: "gerente2@example.com", dni: "10000003", rol: 1 },
  { nombre: "Franco",  email: "empleado@example.com", dni: "10000004", rol: 0 },
  { nombre: "Sofia",   email: "empleado2@example.com", dni: "10000005", rol: 0 },
  { nombre: "Mia",     email: "empleado3@example.com", dni: "10000006", rol: 0 },
  { nombre: "Valentina", email: "empleado4@example.com", dni: "10000007", rol: 0 },
  { nombre: "Matias",  email: "empleado5@example.com", dni: "10000008", rol: 0 }
]
usuarios.each do |attrs|
  Usuario.create!(
    nombre: attrs[:nombre],
    email: attrs[:email],
    dni: attrs[:dni],
    rol: attrs[:rol],
    password: "password",
    password_confirmation: "password"
  )
end
puts "==> Listo: #{Usuario.count} usuarios creados."

img_default = Rails.root.join("app/assets/images/default.png")
audio_default = Rails.root.join("app/assets/audio/default.mp3")

def png_fallback
  StringIO.new(
    "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01"+
    "\x08\x06\x00\x00\x00\x1F\x15\xC4\x89\x00\x00\x00\nIDATx\x9Cc\x00\x01"+
    "\x00\x00\x05\x00\x01\r\n\x2D\xB4\x00\x00\x00\x00IEND\xAE\x42\x60\x82",
    "rb"
  )
end

def io_from(path)
  return png_fallback unless File.exist?(path)
  File.open(path, "rb")
end

def attach_image!(producto, path)
  io = io_from(path)
  producto.imagenes.attach(
    io: io,
    filename: File.exist?(path) ? File.basename(path) : "fallback.png",
    content_type: "image/png"
  )
end

def attach_audio_if_used!(producto, path)
  return unless producto.estado_fisico == "usado"
  return unless File.exist?(path)
  producto.audio_muestra.attach(
    io: File.open(path, "rb"),
    filename: File.basename(path),
    content_type: "audio/mpeg"
  )
end

puts "==> Creando productos"
productos = []
15.times do
  p = Producto.new(
    titulo: Faker::Music.album,
    descripcion: Faker::Lorem.sentence(word_count: 10),
    autor: Faker::Music.band,
    precio: rand(500..5000),
    stock: rand(10..50), # Mayor stock para productos nuevos
    categoria: %w[rock pop jazz metal electronica reggae blues clasica hiphop].sample,
    tipo: %w[vinilo cd].sample,
    estado_fisico: "nuevo",
    anio: rand(1975..2023),
    estado: "activo"
  )
  attach_image!(p, img_default)
  p.save!
  productos << p
end

5.times do
  p = Producto.new(
    titulo: Faker::Music.album,
    descripcion: Faker::Lorem.sentence(word_count: 8),
    autor: Faker::Music.band,
    precio: rand(500..5000),
    stock: 1,
    categoria: %w[rock pop jazz metal electronica].sample,
    tipo: %w[vinilo cd].sample,
    estado_fisico: "usado",
    anio: rand(1975..2020),
    estado: "activo"
  )
  attach_image!(p, img_default)
  attach_audio_if_used!(p, audio_default)
  p.save!
  productos << p
end
puts "==> Listo: #{Producto.count} productos creados."

puts "==> Creando canciones por producto"
productos.each do |prod|
  track_count = rand(6..10)
  track_count.times do |n|
    Cancion.create!(
      producto_id: prod.id,
      nombre: Faker::Music::GratefulDead.song,
      duracion_segundos: rand(120..420),
      orden: n + 1,
      autor: [nil, prod.autor, Faker::Music.band].sample
    )
  end
end
puts "==> Listo: Canciones generadas para #{productos.count} productos."

puts "==> Creando clientes de prueba"
clientes = []
20.times do
  clientes << Cliente.create!(
    nombre: Faker::Name.name,
    dni: Faker::Number.unique.number(digits: 8).to_s,
    telefono: Faker::PhoneNumber.phone_number
  )
end

empleados = Usuario.where(rol: 0).to_a
productos_nuevos = productos.select { |p| p.estado_fisico == "nuevo" && p.stock > 0 }
productos_usados = productos.select { |p| p.estado_fisico == "usado" && p.stock > 0 }

# Distribución desigual de ventas por empleado (este mes)
puts "==> Creando ventas activas (distribución desigual entre empleados)"
ventas_por_empleado = {
  empleados[0] => 8,  # Franco hace 8 ventas
  empleados[1] => 12, # Sofia hace 12 ventas
  empleados[2] => 5   # Mia hace 5 ventas
}

ventas_por_empleado.each do |empleado, cantidad|
  cantidad.times do
    detalles = []
    total = 0
    usados = productos_usados.sample(rand(0..1))
    nuevos = productos_nuevos.sample(rand(1..3))
    (nuevos + usados).uniq.each do |prod|
      cantidad_prod = prod.estado_fisico == "usado" ? 1 : rand(1..[prod.stock, 5].min)
      detalles << { producto_id: prod.id, cantidad: cantidad_prod, precio: prod.precio }
      total += cantidad_prod * prod.precio
    end
    next if detalles.empty?
    Venta.create!(
      fecha_hora: Faker::Time.between(from: Time.current.beginning_of_month, to: Time.current),
      cliente: clientes.sample,
      empleado: empleado,
      total: total,
      pago: %w[efectivo transferencia debito].sample,
      cancelada: false,
      detalle_ventas_attributes: detalles
    )
  end
end

puts "==> Creando ventas canceladas (este mes)"
5.times do
  detalles = []
  total = 0
  usados = productos_usados.sample(rand(0..1))
  nuevos = productos_nuevos.sample(rand(1..2))
  (nuevos + usados).uniq.each do |prod|
    cantidad = prod.estado_fisico == "usado" ? 1 : rand(1..[prod.stock, 3].min)
    detalles << { producto_id: prod.id, cantidad: cantidad, precio: prod.precio }
    total += cantidad * prod.precio
  end
  next if detalles.empty?
  Venta.create!(
    fecha_hora: Faker::Time.between(from: Time.current.beginning_of_month, to: Time.current),
    cliente: clientes.sample,
    empleado: empleados.sample,
    total: total,
    pago: %w[efectivo transferencia debito].sample,
    cancelada: true,
    fecha_cancelacion: Faker::Time.between(from: Time.current.beginning_of_month, to: Time.current),
    detalle_ventas_attributes: detalles
  )
end

puts "==> Listo: #{Venta.count} ventas creadas (#{Venta.where(cancelada: true).count} canceladas, #{Venta.where(cancelada: false).count} activas)."
puts "==> Distribución de ventas activas por empleado:"
ventas_por_empleado.each do |emp, cant|
  puts "   - #{emp.nombre}: #{cant} ventas"
end
