class ProductosController < ApplicationController
  before_action :set_producto, only: %i[show edit update destroy eliminar_imagen]

  def index
    @productos = Producto.filtrar(params).page(params[:page]).per(6)
  end

  def show; end

  def new
    @producto = Producto.new
  end

  def edit; end

  def create
    @producto = Producto.new(producto_params)

    if @producto.save
      redirect_to @producto, notice: "Producto creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # Manejar imágenes por separado para no borrar las existentes
    producto_attrs = producto_params
    nuevas_imagenes = producto_attrs.delete(:imagenes)
    
    if @producto.update(producto_attrs)
      # Solo adjuntar nuevas imágenes si vienen en el formulario
      if nuevas_imagenes.present? && nuevas_imagenes.reject(&:blank?).any?
        @producto.imagenes.attach(nuevas_imagenes.reject(&:blank?))
      end
      
      redirect_to @producto, notice: "Producto actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @producto.eliminar_logicamente
    redirect_to productos_path, notice: "Producto eliminado lógicamente y stock puesto en 0."
  end

  def productos_filtrados
    productos = Producto.para_ventas(tipo: params[:tipo], categoria: params[:categoria])
    render json: productos
  end

  def eliminar_imagen
    imagen = @producto.imagenes.find(params[:imagen_id])
    
    if @producto.imagenes.count <= 1
      redirect_to edit_producto_path(@producto), alert: "No se puede eliminar la última imagen. El producto debe tener al menos una."
    else
      imagen.purge
      redirect_to edit_producto_path(@producto), notice: "Imagen eliminada correctamente."
    end
  end

  def buscar_productos
    query = params[:q].to_s.strip
    if query.length >= 2
      productos = Producto.activos.con_stock
                          .where("LOWER(titulo) LIKE ?", "%#{query.downcase}%")
                          .order(:titulo)
                          .limit(10)
                          .select(:id, :titulo, :precio, :stock, :autor, :categoria)
      render json: productos
    else
      render json: []
    end
  end

  private

  def set_producto
    @producto = Producto.find(params[:id])
  end

  def producto_params
    params.require(:producto).permit(
      :titulo, :descripcion, :autor, :precio, :stock,
      :categoria, :tipo, :estado_fisico, :anio, :estado,
      { imagenes: [] }, :audio_muestra
    )
  end
end
