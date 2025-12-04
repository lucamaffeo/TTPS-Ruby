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
    if params[:venta][:cliente_id].blank?
      cliente = Cliente.find_or_create_by(dni: params[:dni]) do |c|
        c.nombre = params[:nombre]
        c.telefono = params[:telefono]
      end

      params[:venta][:cliente_id] = cliente.id
    end

    @venta = Venta.new(venta_params)
    @venta.empleado = current_usuario
    @venta.fecha_hora = Time.now

    detalles_attrs = (venta_params[:detalle_ventas_attributes] || {}).values
    if detalles_attrs.empty?
      @venta.errors.add(:base, "Debe agregar al menos un producto a la venta")
      @productos = Producto.order(:titulo).limit(200)
      render :new, status: :unprocessable_entity and return
    end

    calculated_total = detalles_attrs.sum { |d| d[:cantidad].to_i * d[:precio].to_f }
    @venta.total = calculated_total

    ActiveRecord::Base.transaction do
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

      if @venta.save
        begin
          @venta.detalle_ventas.each do |dv|
            prod = Producto.lock.find(dv.producto_id)
            prod.update!(stock: prod.stock - dv.cantidad)
          end
        rescue ActiveRecord::RecordInvalid => e
          @venta.errors.add(:base, "Error al actualizar stock: #{e.message}")
          raise ActiveRecord::Rollback
        end
        redirect_to venta_path(@venta), notice: "Venta creada correctamente." and return
      else
        flash.now[:alert] = @venta.errors.full_messages.join(", ")
        raise ActiveRecord::Rollback
      end
    end

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
