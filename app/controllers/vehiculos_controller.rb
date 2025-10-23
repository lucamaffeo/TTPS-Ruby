class VehiculosController < ApplicationController
    def index
        @vehiculos = Vehiculo.includes(:usuario).all
    end
    def show
        @vehiculo = Vehiculo.find(params[:id])
    end
    def new
        @vehiculo = Vehiculo.new
    end
    def create
        @vehiculo = Vehiculo.new(vehiculo_params)
        if @vehiculo.save
            redirect_to @vehiculo, notice: 'Vehículo creado exitosamente.'
        else
            render :new
        end
    end
    def edit
        @vehiculo = Vehiculo.find(params[:id])
    end
    def update
        @vehiculo = Vehiculo.find(params[:id])
        if @vehiculo.update(vehiculo_params)
            redirect_to @vehiculo, notice: 'Vehículo actualizado exitosamente.'
        else
            render :edit
        end
    end
    def destroy
        @vehiculo = Vehiculo.find(params[:id])
        @vehiculo.destroy
        redirect_to vehiculos_url, notice: 'Vehículo eliminado exitosamente.'
    end
    private    
    def vehiculo_params
        params.require(:vehiculo).permit(:marca, :modelo, :anio, :usuario_id)
    end
end