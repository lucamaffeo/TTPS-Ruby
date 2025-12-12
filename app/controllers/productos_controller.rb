class ProductosController < ApplicationController
  before_action :set_producto, only: %i[show edit update destroy]

  def index
    @productos = Producto.all

    # Usar scopes del modelo
    @productos = @productos.buscar(params[:q]) if params[:q].present?
    @productos = @productos.por_categoria(params[:categoria]) if params[:categoria].present?
    @productos = @productos.por_tipo(params[:tipo]) if params[:tipo].present?
    @productos = @productos.por_estado_fisico(params[:estado_fisico]) if params[:estado_fisico].present?

    if params[:stock_filter].present?
      @productos = case params[:stock_filter]
                   when "sin_stock" then @productos.sin_stock
                   when "bajo_stock" then @productos.bajo_stock
                   when "con_stock" then @productos.con_stock
                   else @productos
                   end
    end

    # Ordenamiento
    sort_column = params[:sort] || "titulo"
    sort_direction = params[:direction] || "asc"
    allowed_columns = %w[titulo autor precio stock anio]
    
    @productos = @productos.order("#{sort_column} #{sort_direction}") if allowed_columns.include?(sort_column)
    @productos = @productos.page(params[:page]).per(6)
  end

  def show; end

  def new
    @producto = Producto.new
  end

  def edit; end

  def create
    @producto = Producto.new(producto_params)

    if params[:producto][:imagenes].blank? || params[:producto][:imagenes].reject(&:blank?).empty?
      @producto.errors.add(:imagenes, "debe subir al menos una imagen")
      return render :new, status: :unprocessable_entity
    end

    if @producto.save
      redirect_to @producto, notice: "Producto creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @producto.update(producto_params)
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
    scope = Producto.activos

    scope = scope.por_tipo(params[:tipo]) if params[:tipo].present?
    scope = scope.por_categoria(params[:categoria]) if params[:categoria].present?
    scope = scope.con_stock

    productos = scope.order(:titulo).select(:id, :titulo, :precio, :stock, :estado_fisico)
    render json: productos
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
