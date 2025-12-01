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
audio_default = Rails.root.join("app/assets/audios/default.mp3")

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
  10.times do
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
