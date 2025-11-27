class Storefront::ProductosController < ApplicationController
  layout "storefront"

  # GET /storefront/productos
  # Muestra el catálogo de productos
  def index
    @productos = Producto.all

    # FILTRO POR BÚSQUEDA
    if params[:q].present?
      @productos = @productos.where(
        "titulo ILIKE :q OR descripcion ILIKE :q OR autor ILIKE :q",
        q: "%#{params[:q]}%"
      )
    end

    # FILTRO POR CATEGORÍA
    if params[:categoria].present?
      @productos = @productos.where(categoria: params[:categoria])
    end

    # FILTRO POR TIPO
    if params[:tipo].present?
      @productos = @productos.where(tipo: params[:tipo])
    end

    # FILTRO POR ESTADO
    if params[:estado].present?
      @productos = @productos.where(estado: params[:estado])
    end

     # === ORDEN ASC / DESC ===
     if params[:orden].present?
      case params[:orden]
      when "precio_asc"
        @productos = @productos.order(precio: :asc)
      when "precio_desc"
        @productos = @productos.order(precio: :desc)
      when "nombre_asc"
        @productos = @productos.order(nombre: :asc)
      when "nombre_desc"
        @productos = @productos.order(nombre: :desc)
      end
    end

    # PAGINACIÓN
    @productos = @productos.page(params[:page]).per(8) # 8 productos por página
  end

  # GET /storefront/productos/:id
  # Muestra la página de un producto específico
  def show
    @producto = Producto.find(params[:id])

    # Productos relacionados
    @relacionados = Producto
      .where(categoria: @producto.categoria)
      .where.not(id: @producto.id)
      .limit(4)
  end

end