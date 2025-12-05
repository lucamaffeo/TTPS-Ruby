class ProductosController < ApplicationController
  before_action :set_producto, only: %i[ show edit update destroy ]

  # GET /productos or /productos.json
  def index
    @productos = Producto.all

    # 1. Búsqueda General (Título, Autor)
    if params[:q].present?
      q = params[:q].to_s.downcase
      @productos = @productos.where(
        "LOWER(titulo) LIKE ? OR LOWER(autor) LIKE ?",
        "%#{q}%", "%#{q}%"
      )
    end

    # 2. Categoría
    if params[:categoria].present?
      @productos = @productos.where(categoria: params[:categoria])
    end

    # 3.  Tipo (CD, Vinilo) ---
    if params[:tipo].present?
      @productos = @productos.where(tipo: params[:tipo])
    end

    # 4. Estado Físico
    if params[:estado_fisico].present?
      @productos = @productos.where(estado_fisico: params[:estado_fisico])
    end

    # 5. Filtro de Stock (Muy útil para admin)
    if params[:stock_filter].present?
      case params[:stock_filter]
      when "sin_stock"
        @productos = @productos.where(stock: 0)
      when "bajo_stock"
        @productos = @productos.where("stock > 0 AND stock <= 5")
      when "con_stock"
        @productos = @productos.where("stock > 0")
      end
    end

    # Ordenamiento
    sort_column = params[:sort] || "titulo"
    sort_direction = params[:direction] || "asc"

    allowed_columns = %w[titulo autor precio stock anio]
    if allowed_columns.include?(sort_column)
      @productos = @productos.order("#{sort_column} #{sort_direction}")
    end

    @productos = @productos.page(params[:page]).per(10)
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
    scope = Producto.where.not(estado: "eliminado")  # ...existing filters might querer ignorar eliminados

    if params[:tipo].present?
      tipo = params[:tipo].to_s.strip
      scope = scope.where("lower(tipo) = ?", tipo.downcase)
    end

    if params[:categoria].present?
      categoria = params[:categoria].to_s.strip
      scope = scope.where("lower(categoria) = ?", categoria.downcase)
    end

    # Mostrar productos que tienen stock > 0 OR que sean usados (se venden aun cuando su stock pueda ser 0)
    scope = scope.where("stock > 0 OR estado_fisico = ?", "usado")

    productos = scope.order(:titulo).select(:id, :titulo, :precio, :stock, :estado_fisico)
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
