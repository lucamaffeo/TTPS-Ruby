class UsuariosController < ApplicationController
  before_action :set_usuario, only: %i[show edit update destroy]

  def index
    @usuarios = policy_scope(Usuario)
    authorize Usuario
  end

  def show
    authorize @usuario
  end

  def new
    @usuario = Usuario.new
  end

  def create
    @usuario = Usuario.new(usuario_params)
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
    if @usuario.update(permitted_attributes(@usuario))
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
    permitidos = [:nombre, :email, :dni]
    permitidos << :rol if current_usuario&.administrador?
    params.require(:usuario).permit(permitidos)
  end
end
