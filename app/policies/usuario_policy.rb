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

  # admin puede eliminar usuarios (excepto a sí mismo)
  # gerente puede eliminar solo empleados
  def destroy?
    return false if record.id == user&.id # No puede eliminarse a sí mismo
    return false if record.eliminado? # No puede eliminar un usuario ya eliminado
    
    if user&.administrador?
      true # Admin puede eliminar cualquier usuario (empleados, gerentes, otros admins)
    elsif user&.gerente?
      record.empleado? && !record.gerente? && !record.administrador? # Gerente solo puede eliminar empleados
    else
      false
    end
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
        scope.unscoped # Muestra todos los usuarios (activos y eliminados)
      else
        scope.unscoped.where(id: user&.id, estado: Usuario::ESTADOS[:activo]) # Se muestra a sí mismo si está activo
      end
    end
  end
end
