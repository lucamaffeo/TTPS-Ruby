class VentaController < ApplicationController
  before_action :set_venta, only: %i[ show edit update destroy ]

  # # GET /venta or /venta.json
  def index
    @ventas = Venta.includes(:empleado).order(created_at: :desc)
  end


  # Aca lo que hace es mostrar una venta especifica.
  def show
  end

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
  # # GET /venta/1/edit
  # def edit
  # end

  # Aca lo que hace es crear una nueva venta con los parametros que vienen del formulario.
  def create
    @venta = Venta.new(venta_params)
    @venta.empleado = current_usuario
    @venta.fecha_hora = Time.now

    # Construimos total a partir de los detalles enviados
    detalles_attrs = (venta_params[:detalle_ventas_attributes] || {}).values
    calculated_total = detalles_attrs.sum do |d|
      cantidad = d[:cantidad].to_i
      precio   = d[:precio].to_f
      cantidad * precio
    end
    @venta.total = calculated_total

    
    
    # Transacción: validamos stock y guardamos todo o nada
    ActiveRecord::Base.transaction do
    # 1) Validar existencia y stock antes de guardar
    detalles_attrs.each do |d|
      producto = Producto.lock.find_by(id: d[:producto_id])
      if producto.nil?
        @venta.errors.add(:base, "Producto no encontrado (id=#{d[:producto_id]})")
        raise ActiveRecord::Rollback
      end

      if producto.stock < d[:cantidad].to_i
        @venta.errors.add(:base, "No hay stock suficiente para #{producto.titulo}")
        raise ActiveRecord::Rollback
      end
    end

    # 2) Guardar la venta (y los detailes via nested attributes)
    if @venta.save
      # 3) Descontar stock (ya validado)
      @venta.detalle_ventas.each do |dv|
        prod = Producto.lock.find(dv.producto_id)
        prod.update!(stock: prod.stock - dv.cantidad)
      end

      redirect_to @venta, notice: "Venta creada correctamente." and return
    else
      # Falló alguna validación del modelo Venta o DetalleVenta
      raise ActiveRecord::Rollback
    end
  end

  # Si llegamos acá: hubo rollback
  @productos = Producto.order(:titulo).limit(200)
  render :new, status: :unprocessable_entity
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
    :total,
    :comprador,
    :empleado_id,
    detalle_ventas_attributes: [ :id, :producto_id, :cantidad, :precio, :_destroy ]
  )
  end

end
