class Usuario < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Roles (evitar fallo en db:setup cuando aún no existe la tabla)
  begin
    if ActiveRecord::Base.connection.data_source_exists?("usuarios") &&
       ActiveRecord::Base.connection.column_exists?(:usuarios, :rol)
      enum rol: { empleado: 0, gerente: 1, administrador: 2 }
    end
  rescue StandardError
    # Ignorar durante tareas que cargan el schema
  end

  # Validaciones
  validates :nombre, presence: true
  validates :dni, presence: true, uniqueness: true

  # Validaciones mínimas (Devise ya valida email/password)
  # ...puedes agregar validaciones extra si hace falta...
end
