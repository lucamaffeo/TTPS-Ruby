class VentaController < ApplicationController
  before_action :set_venta, only: %i[ show edit update destroy ]

  # # GET /venta or /venta.json
   def index
     @ventas = Venta.all
   end

  # Aca lo que hace es mostrar una venta especifica.
   def show
   end

  # Aca lo que hace es inicializar una nueva venta y cargar los productos para el formulario.
  def new
    @venta = Venta.new
    @venta.detalle_ventas.build
    @productos = Producto.order(:titulo).limit(200)
    @venta.empleado = current_usuario
  end
  # # GET /venta/1/edit
  # def edit
  # end

  # Aca lo que hace es crear una nueva venta con los parametros que vienen del formulario.
  def create
    @venta = Venta.new(venta_params)
    @venta.empleado = current_usuario if @venta.empleado.nil?

    if @venta.save
      redirect_to @venta, notice: "Venta creada correctamente."
    else
      @productos = Producto.order(:titulo).limit(200)
      render :new, status: :unprocessable_entity
    end
  end
  
  # Aca lo que hace es actualizar una venta especifica.
  def update
    if @venta.update(venta_params)
      redirect_to @venta, notice: "Venta actualizada correctamente."
    else
      @productos = Producto.order(:titulo)
      render :edit, status: :unprocessable_entity
    end
  end
  # Elimina una venta especifica.
  def destroy
    @venta.destroy
    redirect_to ventas_path, notice: "Venta eliminada correctamente."
  end

  # Aca lo que hace es buscar la venta por el id que viene en los parametros de la url.
  def set_venta
    @venta = Venta.find(params[:id])
  end

  # venta_params lo que hace es permitir los parametros para crear o actualizar una venta, vienen del formulario.
  def venta_params
  params.require(:venta).permit(
    :fecha_hora,
    :total,
    :comprador,
    :empleado_id,
    detalle_ventas_attributes: [ :id, :producto_id, :cantidad, :precio, :_destroy ]
  )
  end

end
