class Producto < ApplicationRecord
  # === RELACIONES ===
  # Un producto aparece en muchas ventas a través de la tabla de detalles.
  has_many :detalle_ventas
  has_many :ventas, through: :detalle_ventas
  has_many :canciones, class_name: "Cancion"
  # === VALIDACIONES ===
  validates :titulo, presence: { message: "no puede estar vacío" }, length: { minimum: 2, maximum: 100 }
  validates :autor, presence: { message: "no puede estar vacío" }, length: { minimum: 2, maximum: 100 }
  validates :categoria, presence: { message: "debe seleccionar un género" }
  validates :tipo, presence: { message: "debe seleccionar un tipo" }, inclusion: { in: %w[vinilo cd] }
  validates :anio, numericality: { only_integer: true, greater_than_or_equal_to: 1900, less_than_or_equal_to: Time.current.year }, allow_nil: false
  validates :estado_fisico, inclusion: { in: %w[nuevo usado], message: "debe ser 'nuevo' o 'usado'" }
  validates :descripcion, length: { maximum: 500 }, allow_blank: true
  validates :stock, presence: { message: "no puede estar vacío" }, numericality: { only_integer: true, greater_than_or_equal_to: 0, message: "debe ser un número entero >= 0" }
  validates :precio, presence: { message: "no puede estar vacío" }, numericality: { greater_than: 0, message: "debe ser mayor a 0" }

  # Permite subir fotos y un audio de muestra.
  has_many_attached :imagenes
  has_one_attached :audio_muestra

  before_create :set_default_values
  before_update :set_update_date

  validate :stock_por_estado_fisico
  validate :imagen_obligatoria_en_creacion
  validate :audio_solo_usado
  validate :imagenes_presentes, on: :create

  # Scopes para búsqueda y filtrado
  scope :activos, -> { where.not(estado: "eliminado") }
  scope :con_stock, -> { where("stock > 0") }
  scope :sin_stock, -> { where(stock: 0) }
  scope :bajo_stock, -> { where("stock > 0 AND stock <= 5") }
  scope :buscar, ->(query) {
    return none if query.blank?
    q = query.to_s.downcase
    where("LOWER(titulo) LIKE ? OR LOWER(autor) LIKE ? OR CAST(anio AS TEXT) LIKE ?", "%#{q}%", "%#{q}%", "%#{q}%")
  }
  scope :por_categoria, ->(categoria) { where(categoria: categoria) if categoria.present? }
  scope :por_tipo, ->(tipo) { where(tipo: tipo) if tipo.present? }
  scope :por_estado_fisico, ->(estado_fisico) { where(estado_fisico: estado_fisico) if estado_fisico.present? }
  scope :por_anio, ->(anio) { where(anio: anio) if anio.present? }

  # LÓGICA DE NEGOCIO: Eliminación lógica
  def eliminar_logicamente
    update_columns(
      estado: "eliminado",
      fecha_baja: Date.today,
      stock: 0,
      updated_at: Time.current
    )
  end

  def self.filtrar(params)
    productos = all

    # Búsquedas / filtros usando scopes ya existentes
    productos = productos.buscar(params[:q])                    if params[:q].present?
    productos = productos.por_categoria(params[:categoria])     if params[:categoria].present?
    productos = productos.por_tipo(params[:tipo])               if params[:tipo].present?
    productos = productos.por_estado_fisico(params[:estado_fisico]) if params[:estado_fisico].present?

    if params[:stock_filter].present?
      productos = case params[:stock_filter]
      when "sin_stock"  then productos.sin_stock
      when "bajo_stock" then productos.bajo_stock
      when "con_stock"  then productos.con_stock
      else productos
      end
    end

    # Ordenamiento
    sort_column    = params[:sort]      || "titulo"
    sort_direction = params[:direction] || "asc"
    allowed_columns    = %w[titulo autor precio stock anio]
    allowed_directions = %w[asc desc]

    if allowed_columns.include?(sort_column) && allowed_directions.include?(sort_direction)
      productos = productos.order("#{sort_column} #{sort_direction}")
    end

    productos
  end

  private

  # Setea valores si estan nulos
  def set_default_values
    self.estado = "activo" if self.estado.blank?
    self.fecha_ingreso = Time.current
    self.fecha_modificacion = Time.current
    self.fecha_baja ||= nil
  end

  # Actualiza la fecha de modificación
  def set_update_date
    self.fecha_modificacion = Time.current
    # No modificar self.estado aquí
  end

  def imagen_obligatoria_en_creacion
    # Solo valida en creación (new_record?) o si se intenta guardar sin imágenes
    if new_record? && !imagenes.attached?
      errors.add(:imagenes, "debe subir al menos una imagen")
    elsif persisted? && imagenes.count == 0
      errors.add(:imagenes, "el producto debe tener al menos una imagen")
    end
  end

  def audio_solo_usado
    if audio_muestra.attached? && estado_fisico != "usado"
      errors.add(:audio_muestra, "solo se permite para productos usados")
    end
  end

  def stock_por_estado_fisico
    if estado_fisico == "usado"
      errors.add(:stock, "debe ser 1 para productos usados") unless stock == 1
    end
  end

  def imagenes_presentes
    # Asumiendo ActiveStorage: has_many_attached :imagenes
    return if respond_to?(:imagenes) && imagenes.respond_to?(:attached?) && imagenes.attached?

    errors.add(:imagenes, "debe subir al menos una imagen")
  end
end
