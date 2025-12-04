class Usuario < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Definición de roles sin usar enum (evita conflicto ActiveRecord::Enum)
  ROLES = {
    empleado: 0,
    gerente: 1,
    administrador: 2
  }.freeze

  ROLE_LABELS = {
    empleado: "Empleado",
    gerente: "Gerente",
    administrador: "Administrador"
  }.freeze

  # Devuelve el símbolo del rol (ej :empleado) o nil si no existe
  def rol_sym
    ROLES.key(rol)
  end

  # Devuelve la etiqueta legible, p. ej. "Empleado"
  def rol_label
    key = rol_sym
    key ? ROLE_LABELS[key] : "Desconocido"
  end


  # Helpers de rol (compatibles con lo que usan tus policies: administrador?, gerente?, etc.)
  def empleado?
    rol == ROLES[:empleado]
  end

  def gerente?
    rol == ROLES[:gerente]
  end

  def administrador?
    rol == ROLES[:administrador]
  end

  # Validación: solo roles válidos (0, 1, 2) o nil
  validates :rol,
            inclusion: { in: ROLES.values },
            allow_nil: true

  validates :nombre, presence: true
  validates :dni, presence: true, uniqueness: { message: "ya está en uso" }
  validates :email, presence: true, uniqueness: { message: "ya está en uso" }

  # Mensaje de confirmación de contraseña en español
  validates :password, confirmation: { message: "no coincide con la confirmación" }, if: -> {
    # Aplica cuando hay password cargada (en create o update con cambio)
    password.present?
  }
end
