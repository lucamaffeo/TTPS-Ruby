class UsuarioPolicy < ApplicationPolicy
  def index?
    user&.administrador? || user&.gerente?
  end

  def show?
    user&.administrador? || user&.gerente? || record.id == user&.id
  end

  def update?
    return true if user&.administrador?
    return false if record.administrador? # nadie excepto admin edita admins
    user&.id == record.id || user&.gerente?
  end

  def destroy?
    user&.administrador?
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

  def permitted_attributes
    attrs = [:email, :nombre, :dni, :password, :password_confirmation]
    attrs << :rol if user&.administrador?
    attrs
  end

  class Scope < Scope
    def resolve
      if user&.administrador? || user&.gerente?
        scope.all
      else
        scope.where(id: user&.id)
      end
    end
  end
end
