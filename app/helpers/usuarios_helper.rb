module UsuariosHelper
  def usuario_edit_button_classes(usuario)
    base = "btn btn-as-dark btn-sm"
    policy(usuario).update? ? base : "#{base} button-disabled disabled"
  end

  def usuario_destroy_button_classes(usuario)
    base = "btn btn-as-dark btn-sm"
    policy(usuario).destroy? ? base : "#{base} button-disabled disabled"
  end

  def usuario_new_button_classes
    base = "btn btn-as-dark"
    policy(Usuario).new? ? base : "#{base} button-disabled disabled"
  end
end