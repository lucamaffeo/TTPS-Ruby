class Storefront::ProductosController < ApplicationController
  layout "storefront"

  # GET /storefront/productos
  # Muestra el catálogo de productos
  def index
    @productos = Producto.activos.con_stock

    # Usar scopes del modelo
    @productos = @productos.buscar(params[:q]) if params[:q].present?
    @productos = @productos.por_categoria(params[:categoria]) if params[:categoria].present?
    @productos = @productos.por_tipo(params[:tipo]) if params[:tipo].present?
    @productos = @productos.por_estado_fisico(params[:estado_fisico]) if params[:estado_fisico].present?
    @productos = @productos.por_anio(params[:anio]) if params[:anio].present?

    # Ordenamiento
    if params[:orden].present?
      @productos = case params[:orden]
                   when "precio_asc" then @productos.order(precio: :asc)
                   when "precio_desc" then @productos.order(precio: :desc)
                   when "nombre_asc" then @productos.order(titulo: :asc)
                   when "nombre_desc" then @productos.order(titulo: :desc)
                   when "estado_asc" then @productos.order(estado_fisico: :asc)
                   when "estado_desc" then @productos.order(estado_fisico: :desc)
                   else @productos
                   end
    end

    @productos = @productos.page(params[:page]).per(8) # 8 productos por página
  end

  # GET /storefront/productos/:id
  # Muestra la página de un producto específico
  def show
    @producto = Producto.find(params[:id])

    # Productos relacionados. Busca 4 productos de la misma categoría
    @relacionados = Producto.activos.where(categoria: @producto.categoria).where.not(id: @producto.id).limit(4)
  end

  # Muestra la lista de temas de un disco
  def canciones
    @producto = Producto.find(params[:id])
    @canciones = @producto.canciones.ordenadas
  end

  # No requiere autenticación para index ni show
end
