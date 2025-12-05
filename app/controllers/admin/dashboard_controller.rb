module Admin
  class DashboardController < BaseController
    def index
      @ventas_por_genero = DetalleVenta
                            .joins(:producto)
                            .group('productos.categoria')
                            .sum(:cantidad)
      
      @total_ingresos = Venta.sum(:total)
      @total_ventas   = Venta.count
      @stock_critico  = Producto.where("stock <= 5").count
    end
  end
end