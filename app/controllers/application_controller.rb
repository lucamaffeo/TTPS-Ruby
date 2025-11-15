class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_usuario!
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError do
    redirect_back(fallback_location: root_path, alert: "No autorizado")
  end

  protected

  # Pundit debe usar current_usuario en lugar de current_user
  def pundit_user
    current_usuario
  end

  def configure_permitted_parameters
    # Registro
    devise_parameter_sanitizer.permit(:sign_up, keys: [:nombre, :dni])
    # Edición de cuenta (perfil propio)
    devise_parameter_sanitizer.permit(:account_update, keys: permitted_account_update_params)
  end

  def permitted_account_update_params
    keys = [:email, :nombre, :dni, :password, :password_confirmation, :current_password]
    keys << :rol if current_usuario&.administrador? # solo admin puede cambiar rol
    keys
  end

  # Redirección después de login
  def after_sign_in_path_for(resource)
    if resource.administrador?
      usuarios_path
    else
      productos_path
    end
  end
end
