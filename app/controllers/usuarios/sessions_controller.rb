class Usuarios::SessionsController < Devise::SessionsController
  # ...existing code...

  protected

  # Redireccion despues del login 
  def after_sign_in_path_for(resource)
    # Si la contraseña es por defecto
    if resource.valid_password?("123456")
      edit_usuario_path(resource) # Redirige al formulario de edición de usuario
    else
      super
    end
  end
end