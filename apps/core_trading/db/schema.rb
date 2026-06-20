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

ActiveRecord::Schema[8.1].define(version: 2026_06_20_123522) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "candles", force: :cascade do |t|
    t.datetime "candle_time", null: false
    t.decimal "close", precision: 18, scale: 4, null: false
    t.datetime "created_at", null: false
    t.decimal "high", precision: 18, scale: 4, null: false
    t.decimal "low", precision: 18, scale: 4, null: false
    t.decimal "open", precision: 18, scale: 4, null: false
    t.bigint "security_id", null: false
    t.string "timeframe", null: false
    t.datetime "updated_at", null: false
    t.bigint "volume"
    t.index ["security_id", "timeframe", "candle_time"], name: "index_candles_on_security_id_and_timeframe_and_candle_time", unique: true
  end

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

  create_table "derivative_contracts", force: :cascade do |t|
    t.string "contract_type", null: false
    t.datetime "created_at", null: false
    t.date "expiry_date", null: false
    t.integer "lot_size"
    t.bigint "security_id", null: false
    t.decimal "tick_size", precision: 10, scale: 4
    t.bigint "underlying_id", null: false
    t.datetime "updated_at", null: false
    t.index ["security_id"], name: "index_derivative_contracts_on_security_id", unique: true
    t.index ["underlying_id", "expiry_date"], name: "index_derivative_contracts_on_underlying_id_and_expiry_date"
    t.index ["underlying_id"], name: "index_derivative_contracts_on_underlying_id"
  end

  create_table "dhan_access_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expiry_time", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["expiry_time"], name: "index_dhan_access_tokens_on_expiry_time"
  end

  create_table "exchanges", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_exchanges_on_code", unique: true
  end

  create_table "future_contracts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "derivative_contract_id", null: false
    t.datetime "updated_at", null: false
    t.index ["derivative_contract_id"], name: "index_future_contracts_on_derivative_contract_id"
  end

  create_table "instrument_imports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "failed_rows"
    t.string "source", null: false
    t.integer "success_rows"
    t.integer "total_rows"
    t.datetime "updated_at", null: false
  end

  create_table "instrument_tokens", force: :cascade do |t|
    t.string "broker", null: false
    t.datetime "created_at", null: false
    t.string "exchange_token"
    t.bigint "instrument_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["broker", "token"], name: "index_instrument_tokens_on_broker_and_token", unique: true
    t.index ["instrument_id"], name: "index_instrument_tokens_on_instrument_id"
  end

  create_table "instruments", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.bigint "exchange_id", null: false
    t.string "instrument_type"
    t.string "isin"
    t.string "name"
    t.bigint "security_id", null: false
    t.bigint "segment_id", null: false
    t.string "symbol"
    t.string "trading_symbol"
    t.datetime "updated_at", null: false
    t.index ["exchange_id", "symbol"], name: "index_instruments_on_exchange_id_and_symbol"
    t.index ["exchange_id"], name: "index_instruments_on_exchange_id"
    t.index ["security_id"], name: "index_instruments_on_security_id", unique: true
    t.index ["segment_id"], name: "index_instruments_on_segment_id"
  end

  create_table "option_chain_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "delta", precision: 10, scale: 6
    t.decimal "gamma", precision: 10, scale: 6
    t.decimal "iv", precision: 10, scale: 6
    t.decimal "ltp", precision: 18, scale: 4
    t.integer "oi"
    t.bigint "option_chain_id", null: false
    t.bigint "option_contract_id", null: false
    t.decimal "theta", precision: 10, scale: 6
    t.datetime "updated_at", null: false
    t.decimal "vega", precision: 10, scale: 6
    t.integer "volume"
    t.index ["option_chain_id"], name: "index_option_chain_entries_on_option_chain_id"
    t.index ["option_contract_id"], name: "index_option_chain_entries_on_option_contract_id"
  end

  create_table "option_chains", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "expiry", null: false
    t.datetime "snapshot_at", null: false
    t.bigint "underlying_id", null: false
    t.datetime "updated_at", null: false
    t.index ["underlying_id", "expiry"], name: "index_option_chains_on_underlying_id_and_expiry"
    t.index ["underlying_id"], name: "index_option_chains_on_underlying_id"
  end

  create_table "option_contracts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "derivative_contract_id", null: false
    t.string "option_type", null: false
    t.decimal "strike_price", precision: 18, scale: 4, null: false
    t.datetime "updated_at", null: false
    t.index ["derivative_contract_id"], name: "index_option_contracts_on_derivative_contract_id"
    t.index ["strike_price", "option_type"], name: "index_option_contracts_on_strike_price_and_option_type"
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

  create_table "segments", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.bigint "exchange_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_segments_on_code", unique: true
    t.index ["exchange_id"], name: "index_segments_on_exchange_id"
  end

  create_table "underlyings", force: :cascade do |t|
    t.string "asset_class"
    t.datetime "created_at", null: false
    t.bigint "instrument_id", null: false
    t.datetime "updated_at", null: false
    t.index ["instrument_id"], name: "index_underlyings_on_instrument_id"
  end

  create_table "watchlist_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "instrument_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "watchlist_id", null: false
    t.index ["instrument_id"], name: "index_watchlist_items_on_instrument_id"
    t.index ["watchlist_id", "instrument_id"], name: "index_watchlist_items_on_watchlist_id_and_instrument_id", unique: true
    t.index ["watchlist_id"], name: "index_watchlist_items_on_watchlist_id"
  end

  create_table "watchlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_watchlists_on_name", unique: true
  end

  add_foreign_key "core_corporate_actions", "core_instruments"
  add_foreign_key "core_future_contracts", "core_instruments"
  add_foreign_key "core_instrument_aliases", "core_instruments"
  add_foreign_key "core_market_data_snapshots", "core_instruments"
  add_foreign_key "core_option_contracts", "core_instruments"
  add_foreign_key "core_runtime_configs", "core_execution_profiles"
  add_foreign_key "derivative_contracts", "underlyings"
  add_foreign_key "future_contracts", "derivative_contracts"
  add_foreign_key "instrument_tokens", "instruments"
  add_foreign_key "instruments", "exchanges"
  add_foreign_key "instruments", "segments"
  add_foreign_key "option_chain_entries", "option_chains"
  add_foreign_key "option_chain_entries", "option_contracts"
  add_foreign_key "option_chains", "underlyings"
  add_foreign_key "option_contracts", "derivative_contracts"
  add_foreign_key "segments", "exchanges"
  add_foreign_key "underlyings", "instruments"
  add_foreign_key "watchlist_items", "instruments"
  add_foreign_key "watchlist_items", "watchlists"
end
