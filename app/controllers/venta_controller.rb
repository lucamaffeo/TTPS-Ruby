class VentaController < ApplicationController
  before_action :set_venta, only: %i[ show edit update destroy ]

  # GET /venta or /venta.json
  def index
    @ventas = Venta.all
  end

  # GET /venta/1 or /venta/1.json
  def show
  end

  # GET /venta/new
  def new
    @venta = Venta.new
  end

  # GET /venta/1/edit
  def edit
  end

  # POST /venta or /venta.json
  def create
    @venta = Venta.new(venta_params)

    respond_to do |format|
      if @venta.save
        format.html { redirect_to @venta, notice: "venta was successfully created." }
        format.json { render :show, status: :created, location: @venta }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @venta.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /venta/1 or /venta/1.json
  def update
    respond_to do |format|
      if @venta.update(venta_params)
        format.html { redirect_to @venta, notice: "venta was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @venta }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @venta.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /venta/1 or /venta/1.json
  def destroy
    @venta.destroy!

    respond_to do |format|
      format.html { redirect_to ventas_path, notice: "venta was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_venta
      @venta = Venta.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def venta_params
      params.require(:venta).permit(:fecha_hora, :total, :comprador, :empleado_id)
    end
end
