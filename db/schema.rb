# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_06_001000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "canciones", force: :cascade do |t|
    t.string "autor"
    t.datetime "created_at", null: false
    t.integer "duracion_segundos", default: 0, null: false
    t.string "nombre", null: false
    t.integer "orden"
    t.integer "producto_id", null: false
    t.datetime "updated_at", null: false
    t.index ["producto_id", "orden"], name: "index_canciones_on_producto_id_and_orden"
    t.index ["producto_id"], name: "index_canciones_on_producto_id"
  end

  create_table "categoria", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "nombre"
    t.datetime "updated_at", null: false
  end

  create_table "clientes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "dni"
    t.string "nombre"
    t.string "telefono"
    t.datetime "updated_at", null: false
  end

  create_table "detalle_venta", force: :cascade do |t|
    t.integer "cantidad"
    t.datetime "created_at", null: false
    t.decimal "precio"
    t.integer "producto_id", null: false
    t.datetime "updated_at", null: false
    t.integer "venta_id", null: false
    t.index ["producto_id"], name: "index_detalle_venta_on_producto_id"
    t.index ["venta_id"], name: "index_detalle_venta_on_venta_id"
  end

  create_table "imagen_productos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "es_portada"
    t.integer "producto_id", null: false
    t.datetime "updated_at", null: false
    t.index ["producto_id"], name: "index_imagen_productos_on_producto_id"
  end

  create_table "muestra_audios", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "producto_id", null: false
    t.datetime "updated_at", null: false
    t.index ["producto_id"], name: "index_muestra_audios_on_producto_id"
  end

  create_table "productos", force: :cascade do |t|
    t.integer "anio"
    t.string "autor"
    t.string "categoria"
    t.datetime "created_at", null: false
    t.text "descripcion"
    t.string "estado"
    t.string "estado_fisico"
    t.date "fecha_baja"
    t.date "fecha_ingreso"
    t.date "fecha_modificacion"
    t.decimal "precio"
    t.integer "stock"
    t.string "tipo"
    t.string "titulo"
    t.datetime "updated_at", null: false
  end

  create_table "usuarios", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "dni", null: false
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "estado", default: 0, null: false
    t.string "nombre", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "rol", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["dni"], name: "index_usuarios_on_dni", unique: true
    t.index ["email"], name: "index_usuarios_on_email", unique: true
    t.index ["estado"], name: "index_usuarios_on_estado"
    t.index ["reset_password_token"], name: "index_usuarios_on_reset_password_token", unique: true
    t.index ["rol"], name: "index_usuarios_on_rol"
    t.check_constraint "rol IN (0,1,2)", name: "usuarios_rol_in_range"
  end

  create_table "venta", force: :cascade do |t|
    t.boolean "cancelada", default: false, null: false
    t.integer "cliente_id"
    t.datetime "created_at", null: false
    t.integer "empleado_id", null: false
    t.datetime "fecha_cancelacion", precision: nil
    t.datetime "fecha_hora"
    t.string "pago", default: "efectivo", null: false
    t.decimal "total"
    t.datetime "updated_at", null: false
    t.index ["cancelada"], name: "index_venta_on_cancelada"
    t.index ["cliente_id"], name: "index_venta_on_cliente_id"
    t.index ["empleado_id"], name: "index_venta_on_empleado_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "canciones", "productos"
  add_foreign_key "detalle_venta", "productos"
  add_foreign_key "detalle_venta", "venta", column: "venta_id"
  add_foreign_key "imagen_productos", "productos"
  add_foreign_key "muestra_audios", "productos"
  add_foreign_key "venta", "clientes"
  add_foreign_key "venta", "usuarios", column: "empleado_id"
end
