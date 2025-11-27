class VentaController < ApplicationController
  before_action :set_ventum, only: %i[ show edit update destroy ]

  # GET /venta or /venta.json
  def index
    @venta = Ventum.all
  end

  # GET /venta/1 or /venta/1.json
  def show
  end

  # GET /venta/new
  def new
    @ventum = Ventum.new
  end

  # GET /venta/1/edit
  def edit
  end

  # POST /venta or /venta.json
  def create
    @ventum = Ventum.new(ventum_params)

    respond_to do |format|
      if @ventum.save
        format.html { redirect_to @ventum, notice: "Ventum was successfully created." }
        format.json { render :show, status: :created, location: @ventum }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ventum.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /venta/1 or /venta/1.json
  def update
    respond_to do |format|
      if @ventum.update(ventum_params)
        format.html { redirect_to @ventum, notice: "Ventum was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @ventum }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ventum.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /venta/1 or /venta/1.json
  def destroy
    @ventum.destroy!

    respond_to do |format|
      format.html { redirect_to venta_path, notice: "Ventum was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ventum
      @ventum = Ventum.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def ventum_params
      params.expect(ventum: [ :fecha_hora, :total, :comprador, :empleado_id ])
    end
end
