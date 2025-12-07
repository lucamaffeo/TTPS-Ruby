class UsuarioPolicy < ApplicationPolicy
  # administradores o gerentes puede ver la lista de usuarios
  def index?
    user&.administrador? || user&.gerente?
  end

  def show?
    user&.administrador? || user&.gerente? || record.id == user&.id
  end

  def update?
    return true if user&.administrador? # Admin puede todo
    return false if record.administrador? # nadie excepto admin edita admins
    user&.id == record.id || user&.gerente? # Uno mismo se puede editar, o un gerente.
  end

  # admin puede eliminar usuarios
  def destroy?
    user&.administrador? && record.id != user&.id
  end

  def new?
    user&.administrador? || user&.gerente?
  end

  def create?
    new?
  end

  def reset_password_default?
    user&.administrador? && record.id != user&.id
  end

  # Define qué campos se permiten enviar desde el formulario 
  # Si es admin, puede cambiar el rol. Si no, solo datos básicos
  def permitted_attributes
    attrs = [:email, :nombre, :dni, :password, :password_confirmation]
    attrs << :rol if user&.administrador?
    attrs
  end

  class Scope < Scope
    def resolve
      if user&.administrador? || user&.gerente?
        scope.all # Muestra todos los usuarios".
      else
        scope.where(id: user&.id) # Se muestra a si mismo
      end
    end
  end
end
