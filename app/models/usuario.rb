class Usuario < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  DEFAULT_PASSWORD = "123456".freeze

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

  ESTADOS = {
    activo: 0,
    eliminado: 1
  }.freeze

  ESTADO_LABELS = {
    activo: "Activo",
    eliminado: "Eliminado"
  }.freeze

  # Scope por defecto: solo usuarios activos
  default_scope { where(estado: ESTADOS[:activo]) }

  # Scope para incluir eliminados
  scope :con_eliminados, -> { unscope(where: :estado) }
  scope :solo_eliminados, -> { unscope(where: :estado).where(estado: ESTADOS[:eliminado]) }

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

  # Helpers de estado
  def activo?
    estado == ESTADOS[:activo]
  end

  def eliminado?
    estado == ESTADOS[:eliminado]
  end

  def estado_sym
    ESTADOS.key(estado)
  end

  def estado_label
    key = estado_sym
    key ? ESTADO_LABELS[key] : "Desconocido"
  end

  # Método para baja lógica
  def eliminar_logicamente
    update(estado: ESTADOS[:eliminado])
  end

  # Validación: solo roles válidos (0, 1, 2) o nil
  validates :rol,
            inclusion: { in: ROLES.values },
            allow_nil: true

  validates :nombre, presence: { message: "no puede estar vacío" }, length: { minimum: 2, maximum: 50 }, format: { with: /\A[[:alpha:]\s]+\z/, message: "solo puede contener letras y espacios" }
  validates :dni, presence: { message: "no puede estar vacío" }, uniqueness: { message: "ya está en uso" }, format: { with: /\A\d{7,8}\z/, message: "debe tener 7 u 8 dígitos" }
  validates :email, presence: { message: "no puede estar vacío" }, uniqueness: { message: "ya está en uso" }, format: { with: URI::MailTo::EMAIL_REGEXP, message: "debe ser un email válido" }
  validates :rol, inclusion: { in: ROLES.values, message: "rol inválido" }, allow_nil: false
  validates :estado, inclusion: { in: ESTADOS.values, message: "estado inválido" }, allow_nil: false
  validates :password, confirmation: { message: "no coincide con la confirmación" }, length: { minimum: 6, message: "debe tener al menos 6 caracteres" }, if: :password_required?

  # Mensaje de confirmación de contraseña en español
  validates :password, confirmation: { message: "no coincide con la confirmación" }, if: -> {
    # Aplica cuando hay password cargada (en create o update con cambio)
    password.present?
  }

  # Override de Devise para evitar login de usuarios eliminados
  def active_for_authentication?
    super && activo?
  end

  def inactive_message
    activo? ? super : :deleted_account
  end

  # Construye un usuario con la contraseña default
  def self.con_contraseña_default(attrs)
    usuario = new(attrs)
    usuario.password = DEFAULT_PASSWORD
    usuario.password_confirmation = DEFAULT_PASSWORD
    usuario
  end

  # Aplica la actualización respetando reglas de dominio.
  # Devuelve [ok(boolean), password_cambiada(boolean)]
  def aplicar_actualizacion(attrs, actor)
    upd = attrs.to_h

    # Si se está editando a sí mismo, no puede cambiar email ni dni
    if actor.id == id
      upd.delete("email")
      upd.delete("dni")
      upd.delete(:email)
      upd.delete(:dni)
    end

    # Si password viene en blanco, no tocarla
    if (upd["password"].blank? && upd["password_confirmation"].blank?) &&
       (upd[:password].blank? && upd[:password_confirmation].blank?)
      upd.delete("password")
      upd.delete("password_confirmation")
      upd.delete(:password)
      upd.delete(:password_confirmation)
    end

    if update(upd)
      password_cambiada =
        previous_changes.key?("encrypted_password") &&
        !valid_password?(DEFAULT_PASSWORD)
      [ true, password_cambiada ]
    else
      [ false, false ]
    end
  end

  # Resetea la contraseña a la default, con reglas de dominio.
  # Devuelve [:ok/:forbidden/:error, mensaje]
  def resetear_a_contraseña_default(actor)
    unless actor.administrador?
      return [ :forbidden, "No tenés permisos para esta acción." ]
    end

    if actor.id == id
      return [ :forbidden, "No podés restablecer tu propia contraseña." ]
    end

    self.password = DEFAULT_PASSWORD
    self.password_confirmation = DEFAULT_PASSWORD

    if save
      [ :ok, "Contraseña restablecida a default. Deberá cambiarla al próximo ingreso." ]
    else
      [ :error, errors.full_messages.join(", ") ]
    end
  end

  private

  def password_required?
    password.present?
  end
end
