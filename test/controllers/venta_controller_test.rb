require "test_helper"

class VentaControllerTest < ActionDispatch::IntegrationTest
  setup do
    @venta = venta(:one)
  end

  test "should get index" do
    get venta_url
    assert_response :success
  end

  test "should get new" do
    get new_venta_url
    assert_response :success
  end

  test "should create venta" do
    assert_difference("venta.count") do
      post venta_url, params: { venta: { comprador: @venta.comprador, empleado_id: @venta.empleado_id, fecha_hora: @venta.fecha_hora, total: @venta.total } }
    end

    assert_redirected_to venta_url(venta.last)
  end

  test "should show venta" do
    get venta_url(@venta)
    assert_response :success
  end

  test "should get edit" do
    get edit_venta_url(@venta)
    assert_response :success
  end

  test "should update venta" do
    patch venta_url(@venta), params: { venta: { comprador: @venta.comprador, empleado_id: @venta.empleado_id, fecha_hora: @venta.fecha_hora, total: @venta.total } }
    assert_redirected_to venta_url(@venta)
  end

  test "should destroy venta" do
    assert_difference("venta.count", -1) do
      delete venta_url(@venta)
    end

    assert_redirected_to venta_url
  end
end
