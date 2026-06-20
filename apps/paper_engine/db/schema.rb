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

ActiveRecord::Schema[8.1].define(version: 2026_06_20_084921) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "INR"
    t.string "mode", null: false
    t.string "name", null: false
    t.string "run_id"
    t.string "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "mode", "run_id"], name: "index_accounts_on_tenant_id_and_mode_and_run_id", unique: true
  end

  create_table "broker_profiles", force: :cascade do |t|
    t.boolean "block_penny_stocks"
    t.string "broker_name"
    t.datetime "created_at", null: false
    t.string "error_format"
    t.integer "max_order_qty"
    t.boolean "restrict_illiquid_options"
    t.boolean "supports_amo"
    t.datetime "updated_at", null: false
  end

  create_table "charge_profiles", force: :cascade do |t|
    t.string "broker"
    t.decimal "brokerage_flat"
    t.decimal "brokerage_pct"
    t.datetime "created_at", null: false
    t.decimal "exchange_pct"
    t.decimal "gst_pct"
    t.string "product_type"
    t.decimal "sebi_pct"
    t.string "segment"
    t.decimal "stamp_pct"
    t.decimal "stt_pct"
    t.datetime "updated_at", null: false
  end

  create_table "corporate_action_events", force: :cascade do |t|
    t.string "action_type", null: false
    t.datetime "created_at", null: false
    t.date "ex_date", null: false
    t.string "instrument_id", null: false
    t.decimal "ratio_or_amount", null: false
    t.datetime "updated_at", null: false
  end

  create_table "journal_entries", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.bigint "reference_id", null: false
    t.string "reference_type", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_journal_entries_on_account_id"
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.decimal "credit", default: "0.0"
    t.decimal "debit", default: "0.0"
    t.bigint "journal_entry_id", null: false
    t.string "ledger_account", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_ledger_entries_on_account_id"
    t.index ["journal_entry_id"], name: "index_ledger_entries_on_journal_entry_id"
  end

  create_table "lot_consumptions", force: :cascade do |t|
    t.bigint "closing_trade_id", null: false
    t.string "costing_method", null: false
    t.datetime "created_at", null: false
    t.decimal "exit_price", null: false
    t.decimal "qty_consumed", null: false
    t.decimal "realized_pnl", null: false
    t.bigint "trade_lot_id", null: false
    t.datetime "updated_at", null: false
    t.index ["closing_trade_id"], name: "index_lot_consumptions_on_closing_trade_id"
    t.index ["trade_lot_id"], name: "index_lot_consumptions_on_trade_lot_id"
  end

  create_table "margin_accounts", force: :cascade do |t|
    t.string "account_id"
    t.decimal "available_margin"
    t.decimal "blocked_margin"
    t.decimal "cash_balance"
    t.datetime "created_at", null: false
    t.decimal "mtm_pnl"
    t.decimal "realized_pnl"
    t.datetime "updated_at", null: false
    t.decimal "utilized_margin"
  end

  create_table "margin_events", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.decimal "amount", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.string "reference_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_margin_events_on_account_id"
  end

  create_table "margin_requirements", force: :cascade do |t|
    t.decimal "cash_requirement_pct"
    t.datetime "created_at", null: false
    t.decimal "exposure_margin_pct"
    t.string "product_type"
    t.string "segment"
    t.decimal "span_margin_pct"
    t.string "symbol"
    t.datetime "updated_at", null: false
  end

  create_table "order_status_transitions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "from_status"
    t.datetime "occurred_at", null: false
    t.bigint "paper_order_id", null: false
    t.string "reason"
    t.string "to_status", null: false
    t.datetime "updated_at", null: false
    t.index ["paper_order_id"], name: "index_order_status_transitions_on_paper_order_id"
  end

  create_table "paper_configs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "scope", null: false
    t.datetime "updated_at", null: false
    t.jsonb "value", null: false
    t.index ["scope", "key"], name: "index_paper_configs_on_scope_and_key", unique: true
  end

  create_table "paper_orders", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "client_order_id", null: false
    t.datetime "created_at", null: false
    t.string "instrument_id", null: false
    t.string "order_type", null: false
    t.decimal "price"
    t.string "product_type", null: false
    t.decimal "qty", null: false
    t.string "side", null: false
    t.string "status", default: "PENDING", null: false
    t.string "strategy_id"
    t.string "tif", default: "DAY"
    t.decimal "trigger_price"
    t.datetime "updated_at", null: false
    t.index ["account_id", "status"], name: "index_paper_orders_on_account_id_and_status"
    t.index ["account_id"], name: "index_paper_orders_on_account_id"
    t.index ["client_order_id"], name: "index_paper_orders_on_client_order_id", unique: true
  end

  create_table "paper_risk_profiles", force: :cascade do |t|
    t.string "account_id"
    t.datetime "created_at", null: false
    t.decimal "max_daily_loss"
    t.decimal "max_drawdown_pct"
    t.integer "max_open_positions"
    t.decimal "max_position_size"
    t.decimal "max_symbol_exposure_pct"
    t.string "status"
    t.string "strategy_id"
    t.datetime "updated_at", null: false
  end

  create_table "paper_trades", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "exchange_ts", null: false
    t.decimal "fill_price", null: false
    t.decimal "fill_qty", null: false
    t.decimal "fill_value", null: false
    t.string "instrument_id", null: false
    t.bigint "paper_order_id", null: false
    t.integer "sequence_no"
    t.string "side", null: false
    t.decimal "slippage_applied", default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_paper_trades_on_account_id"
    t.index ["paper_order_id"], name: "index_paper_trades_on_paper_order_id"
  end

  create_table "portfolio_cashflows", force: :cascade do |t|
    t.bigint "account_id"
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.string "flow_type"
    t.string "reference_id"
    t.string "reference_type"
    t.datetime "updated_at", null: false
  end

  create_table "settlement_lots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "quantity"
    t.date "settlement_date"
    t.string "status"
    t.string "symbol"
    t.bigint "trade_id"
    t.datetime "updated_at", null: false
  end

  create_table "trade_lots", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.decimal "entry_price", null: false
    t.string "instrument_id", null: false
    t.bigint "opening_trade_id", null: false
    t.decimal "original_qty", null: false
    t.decimal "remaining_qty", null: false
    t.string "side", null: false
    t.string "status", default: "OPEN"
    t.string "strategy_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_trade_lots_on_account_id"
    t.index ["opening_trade_id"], name: "index_trade_lots_on_opening_trade_id"
  end

  add_foreign_key "journal_entries", "accounts"
  add_foreign_key "ledger_entries", "accounts"
  add_foreign_key "ledger_entries", "journal_entries"
  add_foreign_key "lot_consumptions", "paper_trades", column: "closing_trade_id"
  add_foreign_key "lot_consumptions", "trade_lots"
  add_foreign_key "margin_events", "accounts"
  add_foreign_key "order_status_transitions", "paper_orders"
  add_foreign_key "paper_orders", "accounts"
  add_foreign_key "paper_trades", "accounts"
  add_foreign_key "paper_trades", "paper_orders"
  add_foreign_key "trade_lots", "accounts"
  add_foreign_key "trade_lots", "paper_trades", column: "opening_trade_id"
end
