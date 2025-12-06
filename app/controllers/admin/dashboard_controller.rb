module Admin
  class DashboardController < BaseController
    def index
      # DATOS PARA GRÁFICO DE GÉNEROS 
      @ventas_por_genero = DetalleVenta
                            .joins(:producto)
                            .group('productos.categoria')
                            .sum(:cantidad)

      #. RANKING DE EMPLEADOS (MES ACTUAL)                      
      @top_empleados = Venta.where(fecha_hora: Time.current.all_month)
      .joins(:empleado)
      .group('usuarios.nombre')
      .order('count_all DESC')
      .count                      
      
      @total_ingresos = Venta.sum(:total)
      @total_ventas   = Venta.count
      @stock_critico  = Producto.where("stock <= 5").count
    end
  end
end