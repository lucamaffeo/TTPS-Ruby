class UsuariosController < ApplicationController
  include Pundit

  before_action :set_usuario, only: %i[show edit update destroy]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :usuario_not_authorized

  def index
    @usuarios = policy_scope(Usuario)
    authorize Usuario
  end

  def show
    authorize @usuario
  end

  def new
    @usuario = Usuario.new
    authorize @usuario
  end

  def create
    @usuario = Usuario.new(usuario_params)
    authorize @usuario
    if @usuario.save
      redirect_to @usuario, notice: "Usuario creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @usuario
  end

  def update
    authorize @usuario
    # Quitar password si viene vacío (no actualizar)
    upd = usuario_params
    if upd[:password].blank? && upd[:password_confirmation].blank?
      upd.delete(:password)
      upd.delete(:password_confirmation)
    end
    if @usuario.update(upd)
      redirect_to @usuario, notice: "Usuario actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @usuario
    @usuario.destroy
    redirect_to usuarios_path, notice: "Usuario eliminado."
  end

  private

  def set_usuario
    @usuario = Usuario.find(params[:id])
  end

  def usuario_params
    permitted = policy(@usuario || Usuario).permitted_attributes
    params.require(:usuario).permit(permitted)
  end

  def usuario_not_authorized
    flash[:alert] = "No tenés permisos para realizar esta acción."
    redirect_back(fallback_location: root_path)
  end
end
