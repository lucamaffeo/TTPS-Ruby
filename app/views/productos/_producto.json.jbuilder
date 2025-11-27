json.extract! producto, :id, :titulo, :descripcion, :autor, :precio, :stock, :categoria, :tipo, :estado, :fecha_ingreso, :fecha_modificacion, :fecha_baja, :created_at, :updated_at
json.url producto_url(producto, format: :json)
