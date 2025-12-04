class ClientesController < ApplicationController
  def buscar_por_dni
    cliente = Cliente.find_by(dni: params[:dni])

    if cliente
      render json: {
        existe: true,
        nombre: cliente.nombre,
        telefono: cliente.telefono,
        id: cliente.id
      }
    else
      render json: { existe: false }
    end
  end
end
