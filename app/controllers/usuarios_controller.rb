class UsuariosController < ApplicationController
  include Pundit

  before_action :set_usuario, only: %i[show edit update destroy reset_password_default]
  # Verifica permisos después de cada acción
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :usuario_not_authorized

  # Muestra solo lo que el usuario puede ver.
  def index
    @usuarios = policy_scope(Usuario).page(params[:page]).per(6)
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
    @usuario.password = "123456"
    @usuario.password_confirmation = "123456"
    authorize @usuario
    if @usuario.save
      redirect_to @usuario, notice: "Usuario creado correctamente."
    else
      # Solo muestra los errores en el formulario, no en el flash global
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @usuario
  end

  def update
    authorize @usuario
    upd = usuario_params
    if current_usuario.id == @usuario.id
      upd.delete(:email)
      upd.delete(:dni)
    end
    if upd[:password].blank? && upd[:password_confirmation].blank?
      upd.delete(:password)
      upd.delete(:password_confirmation)
    end
    if @usuario.update(upd)
      # Si el usuario cambió la contraseña inicial, limpia el flag y redirige correctamente
      if @usuario.previous_changes.key?("encrypted_password") && !@usuario.valid_password?("123456")
        session[:require_password_change] = false
        bypass_sign_in(@usuario)
        redirect_to(@usuario.administrador? ? usuarios_path : productos_path, notice: "Contraseña actualizada correctamente.") and return
      end
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

  def reset_password_default
    authorize @usuario
    unless current_usuario.administrador?
      return redirect_to @usuario, alert: "No tenés permisos para esta acción."
    end
    if @usuario.id == current_usuario.id
      return redirect_to @usuario, alert: "No podés restablecer tu propia contraseña."
    end

    @usuario.password = "123456"
    @usuario.password_confirmation = "123456"
    if @usuario.save
      redirect_to @usuario, notice: "Contraseña restablecida a default. Deberá cambiarla al próximo ingreso."
    else
      redirect_to @usuario, alert: @usuario.errors.full_messages.join(", ")
    end
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
