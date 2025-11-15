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
  validates :dni, presence: true, uniqueness: true
end
