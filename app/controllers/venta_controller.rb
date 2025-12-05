class VentaController < ApplicationController
  before_action :authenticate_usuario!, only: %i[new create edit update destroy]
  before_action :set_venta, only: %i[ show edit update destroy ]

  require "prawn"
  require "prawn/table"

  # # GET /venta or /venta.json
  def index
    # incluimos cliente y empleado para evitar N+1; orden por fecha
    @ventas = Venta.left_outer_joins(:cliente).includes(:cliente, :empleado).order(fecha_hora: :desc)

    # 1. Búsqueda por Cliente (nombre en tabla clientes)
    if params[:q].present?
      q = params[:q].to_s.downcase
      # usamos LOWER sobre clientes.nombre; left join permite ventas sin cliente
      @ventas = @ventas.where("LOWER(clientes.nombre) LIKE ?", "%#{q}%")
    end

    # 2. Filtro por Empleado (Usuario)
    if params[:empleado_id].present?
      @ventas = @ventas.where(empleado_id: params[:empleado_id])
    end

    # 3. Filtro por Rango de Fechas
    if params[:fecha_inicio].present?
      fecha_inicio = Date.parse(params[:fecha_inicio]) rescue nil
      @ventas = @ventas.where("fecha_hora >= ?", fecha_inicio.beginning_of_day) if fecha_inicio
    end

    if params[:fecha_fin].present?
      fecha_fin = Date.parse(params[:fecha_fin]) rescue nil
      @ventas = @ventas.where("fecha_hora <= ?", fecha_fin.end_of_day) if fecha_fin
    end

    # Paginación
    @ventas = @ventas.page(params[:page]).per(10)
  end


  # Aca lo que hace es mostrar una venta especifica.
  def show
    respond_to do |format|
      format.html
      format.pdf do
        pdf = Prawn::Document.new(page_size: "A4", margin: [ 30, 30, 30, 30 ])

        # Encabezado con logo y datos empresa
        pdf.image Rails.root.join("app/assets/images/ActiveSound.png"), width: 60, position: :left if File.exist?(Rails.root.join("app/assets/images/ActiveSound.png"))
        pdf.bounding_box([ 80, pdf.cursor + 30 ], width: 400) do
          pdf.text "ActiveSound Disquería", size: 18, style: :bold, color: "222222"
          pdf.text "Factura Nº #{@venta.id}", size: 14, style: :bold
          pdf.text "Fecha: #{@venta.fecha_hora.strftime('%d/%m/%Y %H:%M')}", size: 10
        end
        pdf.move_down 10

        # Datos cliente y vendedor en dos columnas
        pdf.bounding_box([ 0, pdf.cursor ], width: pdf.bounds.width) do
          pdf.bounding_box([ 0, pdf.cursor ], width: pdf.bounds.width / 2 - 10) do
            pdf.text "Cliente", style: :bold, size: 12
            pdf.text "Nombre: #{@venta.cliente&.nombre || @venta.comprador || 'N/A'}", size: 10
            pdf.text "DNI: #{@venta.cliente&.dni || 'N/A'}", size: 10
            pdf.text "Teléfono: #{@venta.cliente&.telefono || 'N/A'}", size: 10
          end
          pdf.bounding_box([ pdf.bounds.width / 2 + 10, pdf.cursor ], width: pdf.bounds.width / 2 - 10) do
            pdf.text "Vendedor", style: :bold, size: 12
            pdf.text "#{@venta.empleado&.nombre || @venta.empleado_id}", size: 10
            pdf.text "Medio de pago: #{@venta.pago.present? ? @venta.pago.humanize : 'N/A'}", size: 10
          end
        end
        pdf.move_down 20

        # Tabla de productos con estilos
        pdf.text "Detalle de productos", style: :bold, size: 13
        pdf.move_down 5
        data = [ [ "Producto", "Cantidad", "Precio unit.", "Subtotal" ] ]
        total = 0.0
        @venta.detalle_ventas.includes(:producto).each do |dv|
          prod = dv.producto
          precio_unit = (dv.precio.present? && dv.precio.to_f > 0) ? dv.precio.to_f : (prod&.precio.to_f || 0.0)
          subtotal = dv.cantidad.to_i * precio_unit
          total += subtotal
          data << [
            prod&.titulo || "Producto eliminado",
            dv.cantidad,
            "$#{'%.2f' % precio_unit}",
            "$#{'%.2f' % subtotal}"
          ]
        end
        data << [ { content: "Total", colspan: 3, align: :right }, "$#{'%.2f' % total}" ]
        pdf.table(data, header: true, width: pdf.bounds.width) do
          row(0).background_color = "222222"
          row(0).text_color = "ffffff"
          row(0).font_style = :bold
          row(-1).font_style = :bold
          row(-1).background_color = "eeeeee"
          columns(1..-1).align = :right
          self.cell_style = { size: 10, padding: [ 6, 4, 6, 4 ] }
        end

        pdf.move_down 30
        pdf.text "Gracias por su compra.", align: :center, size: 12, style: :bold
        pdf.text "Documento generado por ActiveSound", align: :center, size: 9, color: "888888"

        send_data pdf.render,
                  filename: "factura-#{@venta.id}.pdf",
                  type: "application/pdf",
                  disposition: "attachment"
      end
    end
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

        # Para productos usados: cantidad debe ser 1 (ejemplar único)
        if producto.estado_fisico == "usado" && d[:cantidad].to_i != 1
          @venta.errors.add(:base, "El producto '#{producto.titulo}' es usado y sólo permite cantidad 1")
          raise ActiveRecord::Rollback
        end

        # Para nuevos verificamos stock suficiente
        if producto.estado_fisico != "usado" && producto.stock < d[:cantidad].to_i
          @venta.errors.add(:base, "No hay stock suficiente para #{producto.titulo}")
          raise ActiveRecord::Rollback
        end
      end

      if @venta.save
        begin
          @venta.detalle_ventas.each do |dv|
            prod = Producto.lock.find(dv.producto_id)
            # Ajustar stock usando update_column para evitar validaciones que impidan poner 0 en usados
            if prod.estado_fisico == "usado"
              prod.update_column(:stock, 0)
            else
              new_stock = prod.stock.to_i - dv.cantidad.to_i
              new_stock = 0 if new_stock < 0
              prod.update_column(:stock, new_stock)
            end
          end
        rescue ActiveRecord::RecordInvalid => e
          # Mostrar mensajes concretos de validación si existe el record
          detail_msg = if e.respond_to?(:record) && e.record && e.record.respond_to?(:errors)
                         e.record.errors.full_messages.join(", ")
          else
                         e.message
          end
          @venta.errors.add(:base, "Error al actualizar stock: #{detail_msg}")
          raise ActiveRecord::Rollback
        end
        redirect_to venta_path(@venta), notice: "Venta creada correctamente." and return
      else
        raise ActiveRecord::Rollback
      end
    end

    @productos = Producto.order(:titulo).limit(200)
    render :new, status: :unprocessable_entity
  end

  # Aca lo que hace es actualizar una venta especifica.
  def update
    # Sanitize nested detalle_ventas_attributes: remove entries that reference detalle ids
    # that do not belong to this venta (avoids ActiveRecord::RecordNotFound).
    incoming = venta_params.to_h
    if incoming["detalle_ventas_attributes"].is_a?(Hash)
      incoming["detalle_ventas_attributes"] =
        sanitize_detalle_ventas_attributes(incoming["detalle_ventas_attributes"])
    end

    if @venta.update(incoming)
      redirect_to @venta, notice: "Venta actualizada correctamente."
    else
      @productos = Producto.order(:titulo)
      render :edit, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound => e
    @venta.errors.add(:base, "Detalle no encontrado: #{e.message}")
    @productos = Producto.order(:titulo)
    render :edit, status: :unprocessable_entity
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
    :cliente_id,
    :empleado_id,
    detalle_ventas_attributes: [ :id, :producto_id, :cantidad, :precio, :_destroy ]
  )
  end

  private
  # Filtra los atributos de detalle_ventas: mantiene elementos nuevos (sin id) y
  # solo aquellos con id que efectivamente pertenecen a @venta.
  def sanitize_detalle_ventas_attributes(hash_attrs)
    hash_attrs.select do |key, det_attrs|
      next true unless det_attrs.is_a?(Hash)
      if det_attrs["id"].present?
        DetalleVenta.exists?(id: det_attrs["id"].to_i, venta_id: @venta.id)
      else
        true
      end
    end
  end
end
