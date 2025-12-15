class VentaController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_venta, only: %i[ show edit update destroy ]

  # # GET /venta or /venta.json
  def index
    @ventas = Venta.filtrar(params).page(params[:page]).per(10)
  end

  # Aca lo que hace es mostrar una venta especifica.
  def show
    respond_to do |format|
      format.html
      format.pdf do
        send_data @venta.generar_factura_pdf,
                  filename: "factura-#{@venta.id}.pdf",
                  type: "application/pdf",
                  disposition: "attachment"
      end
    end
  end

  # Aca lo que hace es editar una venta especifica.
  def edit
    @venta = Venta.find(params[:id])
    @venta.detalle_ventas.build if @venta.detalle_ventas.empty?
  end

  # Aca lo que hace es inicializar una nueva venta y cargar los productos para el formulario.
  def new
    @venta = Venta.new
    @venta.detalle_ventas.build
    @productos = Producto.order(:titulo).limit(200)
    @venta.empleado = current_usuario
  end

  # Aca lo que hace es crear una nueva venta con los parametros que vienen del formulario.
  def create
    @venta = Venta.construir_desde_formulario(venta_params, params, current_usuario)

    if @venta.guardar_y_actualizar_stock
      redirect_to venta_path(@venta), notice: "Venta creada correctamente."
    else
      @productos = Producto.order(:titulo).limit(200)
      render :new, status: :unprocessable_entity
    end
  end

  # Aca lo que hace es actualizar una venta especifica.
  def update
    if @venta.actualizar_desde_formulario(venta_params, params)
      redirect_to venta_path(@venta), notice: "Venta actualizada correctamente."
    else
      @productos = Producto.order(:titulo)
      render :edit, status: :unprocessable_entity
    end
  end

  # Elimina (lógicamente) una venta especifica.
  def destroy
    if @venta.cancelada?
      redirect_to({ controller: "venta", action: :index }, alert: "La venta ya estaba cancelada.") and return
    end

    begin
      @venta.cancelar!
      redirect_to({ controller: "venta", action: :index }, notice: "Venta cancelada correctamente. Se repuso el stock.")
    rescue => e
      logger.error("Error cancelando venta #{@venta.id}: #{e.message}")
      redirect_to({ controller: "venta", action: :index }, alert: "No se pudo cancelar la venta: #{e.message}")
    end
  end

  # Aca lo que hace es buscar la venta por el id que viene en los parametros de la url.
  def set_venta
    @venta = Venta.find(params[:id])
  end

  # venta_params lo que hace es permitir los parametros para crear o actualizar una venta, vienen del formulario.
  def venta_params
    params.require(:venta).permit(
      :total,
      :pago,               # <-- permitir medio de pago
      :cliente_id,
      :empleado_id,
      detalle_ventas_attributes: [ :id, :producto_id, :cantidad, :precio, :_destroy ]
    )
  end
end
