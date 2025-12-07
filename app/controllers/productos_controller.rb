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

    @productos = @productos.page(params[:page]).per(6) # 6 por página
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

    # Validar que se hayan subido imágenes
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

  # PATCH/PUT /productos/1 or /productos/1.json
  def update
    # Permitir actualización sin requerir nuevas imágenes si ya existen
    if @producto.update(producto_params)
      redirect_to @producto, notice: "Producto actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /productos/1 or /productos/1.json
  # Borrado lógico: No borra el registro, lo marca como "eliminado".
  def destroy
    # Forzar borrado lógico y stock=0 ignorando validaciones que puedan fallar
    @producto.update_columns(
      estado:      "eliminado",
      fecha_baja:  Date.today,
      stock:       0,
      updated_at:  Time.current
    )
    redirect_to productos_path, notice: "Producto eliminado lógicamente y stock puesto en 0."
  end

  # GET /productos_filtrados
  def productos_filtrados
    # No incluir productos eliminados ni con stock 0 (para storefront / selects)
    scope = Producto.where.not(estado: "eliminado")

    if params[:tipo].present?
      tipo = params[:tipo].to_s.strip
      scope = scope.where("lower(tipo) = ?", tipo.downcase)
    end

    if params[:categoria].present?
      categoria = params[:categoria].to_s.strip
      scope = scope.where("lower(categoria) = ?", categoria.downcase)
    end

    # Para storefront: solo productos con stock > 0
    scope = scope.where("stock > 0")

    productos = scope.order(:titulo).select(:id, :titulo, :precio, :stock, :estado_fisico)
    render json: productos
  end


  private
    # Usa llamadas para compartir configuraciones o restricciones comunes entre acciones.
    def set_producto
      @producto = Producto.find(params[:id]) # params.expect(:id)
    end

    # Permitir únicamente una lista de parámetros confiables.
    def producto_params
      params.require(:producto).permit(
        :titulo, :descripcion, :autor, :precio, :stock,
        :categoria, :tipo, :estado_fisico, :anio, :estado,
        { imagenes: [] }, :audio_muestra
      )
    end
end
