class CancionesController < ApplicationController
  before_action :set_producto
  before_action :set_cancion, only: [:edit, :update, :destroy]

  def index
    @canciones = @producto.canciones.order(Arel.sql("COALESCE(orden, 999999), id"))
  end

  def new
    @cancion = @producto.canciones.build
  end

  def create
    @cancion = @producto.canciones.build(cancion_params)
    if @cancion.save
      redirect_to producto_canciones_path(@producto), notice: "Canción creada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @cancion.update(cancion_params)
      redirect_to producto_canciones_path(@producto), notice: "Canción actualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @cancion.destroy
    redirect_to producto_canciones_path(@producto), notice: "Canción eliminada."
  end

  private

  def set_producto
    @producto = Producto.find(params[:producto_id])
  end

  def set_cancion
    @cancion = @producto.canciones.find(params[:id])
  end

  def cancion_params
    params.require(:cancion).permit(:nombre, :duracion_segundos, :orden, :autor)
  end
end
