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

require "faker"
require "stringio"

puts "==> Creando productos de prueba"

img_default = Rails.root.join("app/assets/images/default.png")
audio_default = Rails.root.join("app/assets/audio/default.mp3")

def fallback_png_io
  # PNG mínimo (1x1) en memoria
  StringIO.new(
    "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01"+
    "\x08\x06\x00\x00\x00\x1F\x15\xC4\x89\x00\x00\x00\nIDATx\x9Cc\x00\x01"+
    "\x00\x00\x05\x00\x01\r\n\x2D\xB4\x00\x00\x00\x00IEND\xAE\x42\x60\x82"
  )
end

def io_from_file(path, content_type:)
  return fallback_png_io if content_type.start_with?("image") && !File.exist?(path)
  return nil unless File.exist?(path)
  StringIO.new(File.binread(path)).tap { |io| io.set_encoding(Encoding::BINARY) }
end

def attach_image!(record, path)
  io = io_from_file(path, content_type: "image/png")
  if io
    record.imagenes.attach(io: io, filename: File.exist?(path) ? File.basename(path) : "fallback.png", content_type: "image/png")
  end
end

def attach_audio_if_used!(record, path)
  return unless record.estado_fisico == "usado"
  io = io_from_file(path, content_type: "audio/mpeg")
  if io
    record.audio_muestra.attach(io: io, filename: File.basename(path), content_type: "audio/mpeg")
  end
end

ActiveRecord::Base.transaction do
  15.times do
    p = Producto.new(
      titulo: Faker::Music.album,
      descripcion: Faker::Lorem.sentence(word_count: 10),
      autor: Faker::Music.band,
      precio: rand(500..5000),
      stock: rand(2..15),
      categoria: %w[rock pop jazz metal electronica reggae blues clasica hiphop].sample,
      tipo: %w[vinilo cd].sample,
      estado_fisico: "nuevo",
      anio: rand(1975..2023),
      estado: "activo"
    )
    attach_image!(p, img_default)
    # Audio solo para usados (no aplica aquí)
    p.save!
  end

  5.times do
    p = Producto.new(
      titulo: Faker::Music.album,
      descripcion: Faker::Lorem.sentence(word_count: 8),
      autor: Faker::Music.band,
      precio: rand(500..5000),
      stock: 1, # usado = ejemplar único
      categoria: %w[rock pop jazz metal electronica].sample,
      tipo: %w[vinilo cd].sample,
      estado_fisico: "usado",
      anio: rand(1975..2020),
      estado: "activo"
    )
    attach_image!(p, img_default)
    attach_audio_if_used!(p, audio_default)
    p.save!
  end
end

puts "==> Listo: #{Producto.count} productos creados."

puts "==> Creando canciones por producto"
if ActiveRecord::Base.connection.table_exists?(:canciones)
  Producto.find_each do |prod|
    track_count = rand(6..10)
    (1..track_count).each do |n|
      Cancion.create!(
        producto_id: prod.id,
        nombre: Faker::Music::GratefulDead.song,
        duracion_segundos: rand(120..420),
        orden: n,
        autor: [nil, prod.autor, Faker::Music.band].sample
      )
    end
  end
  puts "==> Listo: Canciones generadas para #{Producto.count} productos."
else
  puts "==> Advertencia: La tabla 'canciones' no existe. Omitiendo creación de canciones."
end

puts "==> Creando ventas de prueba"

empleado = Usuario.find_by(rol: 0)
productos_nuevos = Producto.where(estado_fisico: "nuevo").where("stock > 0").to_a
productos_usados = Producto.where(estado_fisico: "usado").where("stock > 0").to_a

if empleado && productos_nuevos.size >= 1
  20.times do
    detalles = []
    total = 0

    # Siempre incluye al menos un producto nuevo
    prod_nuevo = productos_nuevos.sample
    max_cant_nuevo = [prod_nuevo.stock, rand(1..3)].min
    next if max_cant_nuevo < 1
    cantidad_nuevo = rand(1..max_cant_nuevo)
    detalles << {
      producto_id: prod_nuevo.id,
      cantidad: cantidad_nuevo,
      precio: prod_nuevo.precio
    }
    total += cantidad_nuevo * prod_nuevo.precio

    # Opcionalmente agrega 0-2 productos usados distintos
    otros_usados = productos_usados.reject { |p| p.id == prod_nuevo.id }.sample(rand(0..2))
    Array(otros_usados).each do |prod|
      max_cant = [prod.stock, rand(1..3)].min
      next if max_cant < 1
      cantidad = rand(1..max_cant)
      next if cantidad < 1
      detalles << {
        producto_id: prod.id,
        cantidad: cantidad,
        precio: prod.precio
      }
      total += cantidad * prod.precio
    end

    next if detalles.empty?

    venta = Venta.create(
      fecha_hora: Faker::Time.backward(days: 30, period: :evening),
      comprador: Faker::Name.name,
      empleado: empleado,
      total: total,
      detalle_ventas_attributes: detalles
    )

    puts "Venta no creada: #{venta.errors.full_messages.join(', ')}" unless venta.persisted?
  end
end

puts "==> Listo: #{Venta.count} ventas creadas."
