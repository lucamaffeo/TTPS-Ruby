class Storefront::ProductosController < ApplicationController
  layout "storefront"

  # GET /storefront/productos
  # Muestra el catálogo de productos
  def index
    @productos = Producto.all

    # FILTRO POR BÚSQUEDA (título, artista o año)
    if params[:q].present?
      q = params[:q].to_s.downcase
      @productos = @productos.where(
        "LOWER(titulo) LIKE ? OR LOWER(autor) LIKE ? OR CAST(anio AS TEXT) LIKE ?",
        "%#{q}%", "%#{q}%", "%#{q}%"
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

    # FILTRO POR ESTADO FÍSICO
    if params[:estado_fisico].present?
      @productos = @productos.where(estado_fisico: params[:estado_fisico])
    end

    # FILTRO POR AÑO
    if params[:anio].present?
      @productos = @productos.where(anio: params[:anio])
    end

     # === ORDEN ASC / DESC ===
     if params[:orden].present?
      case params[:orden]
      when "precio_asc"
        @productos = @productos.order(precio: :asc)
      when "precio_desc"
        @productos = @productos.order(precio: :desc)
      when "nombre_asc"
        @productos = @productos.order(titulo: :asc)
      when "nombre_desc"
        @productos = @productos.order(titulo: :desc)
      when "estado_asc"
        @productos = @productos.order(estado_fisico: :asc)
      when "estado_desc"
        @productos = @productos.order(estado_fisico: :desc)  
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

  def canciones
    @producto = Producto.find(params[:id])
    @canciones = @producto.canciones.order(Arel.sql("COALESCE(orden, 999999), id"))
  end

  # No requiere autenticación para index ni show
end