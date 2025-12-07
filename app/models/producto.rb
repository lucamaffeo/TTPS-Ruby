class Producto < ApplicationRecord
  # === RELACIONES ===
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

  has_many_attached :imagenes
  has_one_attached :audio_muestra

  before_create :set_default_values
  before_update :set_update_date

  validate :stock_por_estado_fisico
  validate :imagen_obligatoria_en_creacion
  validate :audio_solo_usado

  private

  def set_default_values
    self.estado = "activo" if self.estado.blank?
    self.fecha_ingreso = Time.current
    self.fecha_modificacion = Time.current
    self.fecha_baja ||= nil
  end

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
end
