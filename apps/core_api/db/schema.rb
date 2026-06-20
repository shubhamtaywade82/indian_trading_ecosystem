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

ActiveRecord::Schema[8.1].define(version: 2026_06_20_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "position_trackers", force: :cascade do |t|
    t.decimal "avg_price", precision: 16, scale: 4
    t.datetime "created_at", null: false
    t.decimal "entry_price", precision: 16, scale: 4
    t.decimal "exit_price", precision: 16, scale: 4
    t.datetime "exited_at"
    t.decimal "high_water_mark_pnl", precision: 16, scale: 4
    t.string "instrument_type"
    t.decimal "last_pnl_rupees", precision: 16, scale: 4
    t.jsonb "meta", default: {}
    t.string "order_no", null: false
    t.boolean "paper", default: false, null: false
    t.integer "quantity", null: false
    t.string "security_id", null: false
    t.string "segment", null: false
    t.string "side", null: false
    t.integer "status", default: 0, null: false
    t.string "symbol"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_position_trackers_on_created_at"
    t.index ["order_no"], name: "index_position_trackers_on_order_no", unique: true
    t.index ["paper", "status"], name: "index_position_trackers_on_paper_and_status"
    t.index ["security_id", "status"], name: "index_position_trackers_on_security_id_and_status"
  end
end
