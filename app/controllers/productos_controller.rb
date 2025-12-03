class ProductosController < ApplicationController
  before_action :set_producto, only: %i[ show edit update destroy ]

  # GET /productos or /productos.json
  def index
    @productos = Producto.all
  end

  # GET /productos/1 or /productos/1.json
  def show
  end

  # GET /productos/new
  def new
    @producto = Producto.new
  end

  # GET /productos/1/edit
  def edit
  end

  # POST /productos or /productos.json
  def create
    @producto = Producto.new(producto_params)

    if @producto.save
      redirect_to @producto, notice: "Producto creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /productos/1 or /productos/1.json
  def update
    if @producto.update(producto_params)
      redirect_to @producto, notice: "Producto actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /productos/1 or /productos/1.json
  def destroy
    @producto.update(estado: "eliminado", fecha_baja: Date.today)
    redirect_to productos_path, notice: "Producto eliminado lógicamente."
  end

  # GET /productos_filtrados
  def productos_filtrados
    scope = Producto.all

    if params[:tipo].present?
      tipo = params[:tipo].to_s.strip
      scope = scope.where('lower(tipo) = ?', tipo.downcase)
    end

    if params[:categoria].present?
      categoria = params[:categoria].to_s.strip
      scope = scope.where('lower(categoria) = ?', categoria.downcase)
    end

    productos = scope.order(:titulo).select(:id, :titulo, :precio)

    render json: productos
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_producto
      @producto = Producto.find(params[:id]) # params.expect(:id)
    end

    # Only allow a list of trusted parameters through.
    def producto_params
      params.require(:producto).permit(
        :titulo, :descripcion, :autor, :precio, :stock,
        :categoria, :tipo, :estado_fisico, :anio, :estado,
        { imagenes: [] }, :audio_muestra
      )
    end

end
