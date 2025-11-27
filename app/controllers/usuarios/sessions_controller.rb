class Usuarios::SessionsController < Devise::SessionsController
  # ...existing code...

  protected

  def after_sign_in_path_for(resource)
    if resource.valid_password?("123456")
      edit_usuario_path(resource) # Redirige al formulario de edición de usuario
    else
      super
    end
  end
end