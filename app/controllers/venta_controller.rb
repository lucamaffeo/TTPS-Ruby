class VentaController < ApplicationController
  before_action :authenticate_usuario!, only: %i[new create edit update destroy]
  before_action :set_venta, only: %i[show edit update destroy]

  require "prawn"
  require "prawn/table"

  def index
    @ventas = Venta.left_outer_joins(:cliente).includes(:cliente, :empleado).order(fecha_hora: :desc)

    @ventas = @ventas.where("LOWER(clientes.nombre) LIKE ?", "%#{params[:q].to_s.downcase}%") if params[:q].present?
    @ventas = @ventas.where(empleado_id: params[:empleado_id]) if params[:empleado_id].present?

    if params[:fecha_inicio].present?
      fecha_inicio = Date.parse(params[:fecha_inicio]) rescue nil
      @ventas = @ventas.where("fecha_hora >= ?", fecha_inicio.beginning_of_day) if fecha_inicio
    end

    if params[:fecha_fin].present?
      fecha_fin = Date.parse(params[:fecha_fin]) rescue nil
      @ventas = @ventas.where("fecha_hora <= ?", fecha_fin.end_of_day) if fecha_fin
    end

    @ventas = @ventas.page(params[:page]).per(10)
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        pdf = Prawn::Document.new(page_size: "A4", margin: [30, 30, 30, 30])

        # Encabezado con logo y datos empresa
        pdf.image Rails.root.join("app/assets/images/ActiveSound.png"), width: 60, position: :left if File.exist?(Rails.root.join("app/assets/images/ActiveSound.png"))
        pdf.bounding_box([80, pdf.cursor + 30], width: 400) do
          pdf.text "ActiveSound Disquería", size: 18, style: :bold, color: "222222"
          pdf.text "Factura Nº #{@venta.id}", size: 14, style: :bold
          pdf.text "Fecha: #{@venta.fecha_hora.strftime('%d/%m/%Y %H:%M')}", size: 10
        end
        pdf.move_down 10

        # Datos cliente y vendedor en dos columnas
        pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width) do
          pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width / 2 - 10) do
            pdf.text "Cliente", style: :bold, size: 12
            pdf.text "Nombre: #{@venta.cliente&.nombre || @venta.comprador || 'N/A'}", size: 10
            pdf.text "DNI: #{@venta.cliente&.dni || 'N/A'}", size: 10
            pdf.text "Teléfono: #{@venta.cliente&.telefono || 'N/A'}", size: 10
          end
          pdf.bounding_box([pdf.bounds.width / 2 + 10, pdf.cursor], width: pdf.bounds.width / 2 - 10) do
            pdf.text "Vendedor", style: :bold, size: 12
            pdf.text "#{@venta.empleado&.nombre || @venta.empleado_id}", size: 10
            pdf.text "Medio de pago: #{@venta.pago.present? ? @venta.pago.humanize : 'N/A'}", size: 10
          end
        end
        pdf.move_down 20

        # Tabla de productos con estilos
        pdf.text "Detalle de productos", style: :bold, size: 13
        pdf.move_down 5
        data = [["Producto", "Cantidad", "Precio unit.", "Subtotal"]]
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
        data << [{ content: "Total", colspan: 3, align: :right }, "$#{'%.2f' % total}"]
        pdf.table(data, header: true, width: pdf.bounds.width) do
          row(0).background_color = "222222"
          row(0).text_color = "ffffff"
          row(0).font_style = :bold
          row(-1).font_style = :bold
          row(-1).background_color = "eeeeee"
          columns(1..-1).align = :right
          self.cell_style = { size: 10, padding: [6, 4, 6, 4] }
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
    @venta.detalle_ventas.build if @venta.detalle_ventas.empty?
  end

  def new
    @venta = Venta.new
    @venta.detalle_ventas.build
    @productos = Producto.order(:titulo).limit(200)
    @venta.empleado = current_usuario
  end

  def create
    @venta = Venta.new(venta_params)
    @venta.empleado = current_usuario
    @venta.fecha_hora = Time.now

    # Procesar cliente usando lógica del modelo
    if params[:venta][:cliente_id].blank?
      resultado = @venta.procesar_cliente_desde_params(
        dni: params[:dni].to_s.strip,
        nombre: params[:nombre].to_s.strip,
        telefono: params[:telefono].to_s.strip
      )

      unless resultado[:success]
        @venta.errors.add(:base, resultado[:error])
        @productos = Producto.order(:titulo).limit(200)
        return render :new, status: :unprocessable_entity
      end

      @venta.cliente = resultado[:cliente]
    end

    # Validar que haya detalles
    detalles_attrs = (venta_params[:detalle_ventas_attributes] || {}).values
    if detalles_attrs.empty?
      @venta.errors.add(:base, "Debe agregar al menos un producto a la venta")
      @productos = Producto.order(:titulo).limit(200)
      return render :new, status: :unprocessable_entity
    end

    # Calcular total usando lógica del modelo
    @venta.total = @venta.calcular_total

    # Validar y actualizar stock usando lógica del modelo
    if @venta.validar_y_actualizar_stock_crear
      redirect_to venta_path(@venta), notice: "Venta creada correctamente."
    else
      @productos = Producto.order(:titulo).limit(200)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    incoming = venta_params.to_h

    # Procesar cliente usando lógica del modelo
    dni = params[:dni].to_s.strip
    nombre = params[:nombre].to_s.strip
    telefono = params[:telefono].to_s.strip

    begin
      if dni.present?
        cliente_existente = Cliente.find_by(dni: dni)
        if cliente_existente
          cliente_existente.update(nombre: nombre) if nombre.present?
          cliente_existente.update(telefono: telefono) if telefono.present?
          incoming["cliente_id"] = cliente_existente.id
        else
          if incoming["cliente_id"].present?
            cli = Cliente.find_by(id: incoming["cliente_id"])
            if cli
              cli.update(dni: dni) if dni.present?
              cli.update(nombre: nombre) if nombre.present?
              cli.update(telefono: telefono) if telefono.present?
            else
              nuevo = Cliente.create!(dni: dni, nombre: nombre.presence || "", telefono: telefono.presence || "")
              incoming["cliente_id"] = nuevo.id
            end
          else
            nuevo = Cliente.create!(dni: dni, nombre: nombre.presence || "", telefono: telefono.presence || "")
            incoming["cliente_id"] = nuevo.id
          end
        end
      else
        if incoming["cliente_id"].present? && (nombre.present? || telefono.present?)
          cli = Cliente.find_by(id: incoming["cliente_id"])
          if cli
            cli.update(nombre: nombre) if nombre.present?
            cli.update(telefono: telefono) if telefono.present?
          end
        end
      end
    rescue => e
      @venta.errors.add(:base, "Error procesando cliente: #{e.message}")
      @productos = Producto.order(:titulo)
      return render :edit, status: :unprocessable_entity
    end

    detalles_incoming = incoming["detalle_ventas_attributes"].is_a?(Hash) ? incoming["detalle_ventas_attributes"] : {}

    ActiveRecord::Base.transaction do
      # Calcular cambios de stock usando lógica del modelo
      stock_changes = @venta.calcular_cambios_stock(detalles_incoming)

      # Validar disponibilidad de stock
      stock_changes.each do |chg|
        next unless chg[:delta_needed]
        next if chg[:delta_needed] <= 0
        
        prod = Producto.lock.find_by(id: chg[:producto_id])
        unless prod
          @venta.errors.add(:base, "Producto no encontrado (id=#{chg[:producto_id]})")
          raise ActiveRecord::Rollback
        end

        if prod.stock.to_i < chg[:delta_needed]
          @venta.errors.add(:base, "No hay stock suficiente para #{prod.titulo}")
          raise ActiveRecord::Rollback
        end
      end

      @venta.update!(incoming)

      # Aplicar cambios de stock usando lógica del modelo
      @venta.aplicar_cambios_stock(stock_changes)

      redirect_to venta_path(@venta), notice: "Venta actualizada correctamente." and return
    end
  rescue ActiveRecord::RecordInvalid => e
    detail_msg = e.respond_to?(:record) && e.record ? e.record.errors.full_messages.join(", ") : e.message
    @venta.errors.add(:base, detail_msg)
    @productos = Producto.order(:titulo)
    render :edit, status: :unprocessable_entity
  end

  def destroy
    if @venta.cancelada?
      redirect_to ventas_path, alert: "La venta ya estaba cancelada."
      return
    end

    begin
      @venta.cancelar!
      redirect_to ventas_path, notice: "Venta cancelada correctamente. Se repuso el stock."
    rescue => e
      logger.error("Error cancelando venta #{@venta.id}: #{e.message}")
      redirect_to ventas_path, alert: "No se pudo cancelar la venta: #{e.message}"
    end
  end

  private

  def set_venta
    @venta = Venta.find(params[:id])
  end

  def venta_params
    params.require(:venta).permit(
      :total,
      :pago,
      :cliente_id,
      :empleado_id,
      detalle_ventas_attributes: [:id, :producto_id, :cantidad, :precio, :_destroy]
    )
  end
end
