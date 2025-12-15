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
    @usuario = Usuario.con_contraseña_default(usuario_params)
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

    ok, password_cambiada = @usuario.aplicar_actualizacion(usuario_params, current_usuario)

    if ok
      if password_cambiada
        session[:require_password_change] = false
        bypass_sign_in(@usuario)
        redirect_to(@usuario.administrador? ? usuarios_path : productos_path,
                    notice: "Contraseña actualizada correctamente.") and return
      end
      redirect_to @usuario, notice: "Usuario actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @usuario
    if @usuario.eliminar_logicamente
      redirect_to usuarios_path, notice: "Usuario eliminado correctamente."
    else
      redirect_to usuarios_path, alert: "No se pudo eliminar el usuario."
    end
  end

  def reset_password_default
    authorize @usuario

    estado, mensaje = @usuario.resetear_a_contraseña_default(current_usuario)

    case estado
    when :ok
      redirect_to @usuario, notice: mensaje
    else
      redirect_to @usuario, alert: mensaje
    end
  end

  private

  def set_usuario
    @usuario = Usuario.unscoped.find(params[:id])
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
