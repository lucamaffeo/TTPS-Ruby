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

ActiveRecord::Schema[8.1].define(version: 2025_10_30_185101) do
  create_table "usuarios", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "dni", null: false
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "nombre", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "rol", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["dni"], name: "index_usuarios_on_dni", unique: true
    t.index ["email"], name: "index_usuarios_on_email", unique: true
    t.index ["reset_password_token"], name: "index_usuarios_on_reset_password_token", unique: true
    t.index ["rol"], name: "index_usuarios_on_rol"
    t.check_constraint "rol IN (0,1,2)", name: "usuarios_rol_in_range"
  end
end
