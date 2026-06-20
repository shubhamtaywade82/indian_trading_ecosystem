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

ActiveRecord::Schema[8.1].define(version: 2026_06_20_075611) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "core_corporate_actions", force: :cascade do |t|
    t.string "action_type", null: false
    t.bigint "core_instrument_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "details", default: {}
    t.date "ex_date", null: false
    t.date "record_date"
    t.datetime "updated_at", null: false
    t.index ["core_instrument_id"], name: "index_core_corporate_actions_on_core_instrument_id"
  end

  create_table "core_execution_profiles", force: :cascade do |t|
    t.string "adapter_name", null: false
    t.jsonb "capabilities", default: {}
    t.jsonb "config", default: {}
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "core_future_contracts", force: :cascade do |t|
    t.bigint "core_instrument_id", null: false
    t.datetime "created_at", null: false
    t.date "expiry_date", null: false
    t.string "underlying_symbol", null: false
    t.datetime "updated_at", null: false
    t.index ["core_instrument_id"], name: "index_core_future_contracts_on_core_instrument_id"
  end

  create_table "core_instrument_aliases", force: :cascade do |t|
    t.string "alias_name", null: false
    t.bigint "core_instrument_id", null: false
    t.datetime "created_at", null: false
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["alias_name", "provider"], name: "index_core_instrument_aliases_on_alias_name_and_provider", unique: true
    t.index ["core_instrument_id"], name: "index_core_instrument_aliases_on_core_instrument_id"
  end

  create_table "core_instruments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "exchange", null: false
    t.string "instrument_type", null: false
    t.string "isin"
    t.decimal "lot_size", default: "1.0"
    t.string "name"
    t.string "segment", null: false
    t.string "symbol", null: false
    t.decimal "tick_size", default: "0.05"
    t.datetime "updated_at", null: false
    t.index ["symbol", "exchange"], name: "index_core_instruments_on_symbol_and_exchange", unique: true
  end

  create_table "core_market_data_snapshots", force: :cascade do |t|
    t.decimal "ask"
    t.decimal "bid"
    t.decimal "close"
    t.bigint "core_instrument_id", null: false
    t.datetime "created_at", null: false
    t.decimal "high"
    t.decimal "last_price"
    t.decimal "low"
    t.decimal "open"
    t.datetime "timestamp"
    t.datetime "updated_at", null: false
    t.decimal "volume"
    t.index ["core_instrument_id"], name: "index_core_market_data_snapshots_on_core_instrument_id"
  end

  create_table "core_option_contracts", force: :cascade do |t|
    t.bigint "core_instrument_id", null: false
    t.datetime "created_at", null: false
    t.date "expiry_date", null: false
    t.string "option_type", null: false
    t.decimal "strike_price", null: false
    t.string "underlying_symbol", null: false
    t.datetime "updated_at", null: false
    t.index ["core_instrument_id"], name: "index_core_option_contracts_on_core_instrument_id"
  end

  create_table "core_runtime_configs", force: :cascade do |t|
    t.bigint "core_execution_profile_id"
    t.datetime "created_at", null: false
    t.string "market_data_source", null: false
    t.string "mode", null: false
    t.string "name", null: false
    t.jsonb "settings", default: {}
    t.datetime "updated_at", null: false
    t.index ["core_execution_profile_id"], name: "index_core_runtime_configs_on_core_execution_profile_id"
  end

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

  add_foreign_key "core_corporate_actions", "core_instruments"
  add_foreign_key "core_future_contracts", "core_instruments"
  add_foreign_key "core_instrument_aliases", "core_instruments"
  add_foreign_key "core_market_data_snapshots", "core_instruments"
  add_foreign_key "core_option_contracts", "core_instruments"
  add_foreign_key "core_runtime_configs", "core_execution_profiles"
end
