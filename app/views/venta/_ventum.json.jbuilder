json.extract! venta, :id, :fecha_hora, :total, :comprador, :empleado_id, :created_at, :updated_at
json.url url_for(controller: "venta", action: :show, id: venta, format: :json)
