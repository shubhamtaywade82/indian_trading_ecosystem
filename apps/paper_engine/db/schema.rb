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

ActiveRecord::Schema[8.1].define(version: 2026_06_20_070422) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency"
    t.string "name"
    t.bigint "runtime_id"
    t.datetime "updated_at", null: false
    t.index ["runtime_id"], name: "index_accounts_on_runtime_id"
  end

  create_table "domain_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type"
    t.datetime "occurred_at"
    t.jsonb "payload"
    t.bigint "runtime_id"
    t.datetime "updated_at", null: false
    t.index ["runtime_id"], name: "index_domain_events_on_runtime_id"
  end

  create_table "idempotency_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.bigint "resource_id"
    t.string "resource_type"
    t.bigint "runtime_id"
    t.datetime "updated_at", null: false
    t.index ["runtime_id"], name: "index_idempotency_keys_on_runtime_id"
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.string "account_code"
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.decimal "credit", default: "0.0"
    t.decimal "debit", default: "0.0"
    t.string "entry_type"
    t.bigint "reference_id"
    t.string "reference_type"
    t.bigint "runtime_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_ledger_entries_on_account_id"
    t.index ["runtime_id"], name: "index_ledger_entries_on_runtime_id"
  end

  create_table "margin_requirements", force: :cascade do |t|
    t.decimal "cash_requirement_pct", default: "1.0"
    t.datetime "created_at", null: false
    t.decimal "exposure_margin_pct", default: "0.0"
    t.string "product_type", null: false
    t.string "segment", null: false
    t.decimal "span_margin_pct", default: "0.0"
    t.string "symbol"
    t.datetime "updated_at", null: false
    t.index ["segment", "product_type", "symbol"], name: "idx_margin_req_lookup", unique: true
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "account_id"
    t.decimal "average_price"
    t.string "correlation_id"
    t.datetime "created_at", null: false
    t.string "exchange"
    t.datetime "expires_at"
    t.uuid "external_order_id"
    t.integer "filled_quantity", default: 0
    t.string "order_type"
    t.decimal "price"
    t.string "product_type"
    t.integer "quantity"
    t.bigint "runtime_id"
    t.string "segment"
    t.string "side"
    t.string "status"
    t.string "symbol"
    t.decimal "trigger_price"
    t.datetime "updated_at", null: false
    t.string "validity"
    t.index ["account_id"], name: "index_orders_on_account_id"
    t.index ["runtime_id"], name: "index_orders_on_runtime_id"
  end

  create_table "paper_execution_queues", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.decimal "price", null: false
    t.bigint "queue_position", null: false
    t.integer "remaining_quantity", null: false
    t.bigint "runtime_id", null: false
    t.string "side", null: false
    t.string "symbol", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_paper_execution_queues_on_order_id"
    t.index ["runtime_id", "symbol", "side", "price", "queue_position"], name: "idx_execution_queue_priority"
    t.index ["runtime_id"], name: "index_paper_execution_queues_on_runtime_id"
  end

  create_table "paper_funds", force: :cascade do |t|
    t.bigint "account_id"
    t.decimal "available_balance", default: "0.0"
    t.decimal "blocked_balance", default: "0.0"
    t.decimal "cash_balance", default: "0.0"
    t.datetime "created_at", null: false
    t.bigint "runtime_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_paper_funds_on_account_id"
    t.index ["runtime_id"], name: "index_paper_funds_on_runtime_id"
  end

  create_table "paper_holdings", force: :cascade do |t|
    t.bigint "account_id"
    t.decimal "average_price", default: "0.0"
    t.datetime "created_at", null: false
    t.integer "quantity", default: 0
    t.bigint "runtime_id"
    t.string "symbol"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_paper_holdings_on_account_id"
    t.index ["runtime_id"], name: "index_paper_holdings_on_runtime_id"
  end

  create_table "paper_margin_accounts", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.decimal "available_margin", default: "0.0"
    t.decimal "blocked_margin", default: "0.0"
    t.decimal "cash_balance", default: "0.0"
    t.datetime "created_at", null: false
    t.decimal "mtm_pnl", default: "0.0"
    t.decimal "realized_pnl", default: "0.0"
    t.bigint "runtime_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "utilized_margin", default: "0.0"
    t.index ["account_id"], name: "index_paper_margin_accounts_on_account_id"
    t.index ["runtime_id"], name: "index_paper_margin_accounts_on_runtime_id"
  end

  create_table "paper_positions", force: :cascade do |t|
    t.bigint "account_id"
    t.decimal "average_price", default: "0.0"
    t.datetime "created_at", null: false
    t.integer "quantity", default: 0
    t.decimal "realized_pnl", default: "0.0"
    t.bigint "runtime_id"
    t.string "symbol"
    t.decimal "unrealized_pnl", default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_paper_positions_on_account_id"
    t.index ["runtime_id"], name: "index_paper_positions_on_runtime_id"
  end

  create_table "runtime_configs", force: :cascade do |t|
    t.string "brokerage_plan"
    t.datetime "created_at", null: false
    t.string "latency_model"
    t.integer "rng_seed"
    t.bigint "runtime_id"
    t.jsonb "settings"
    t.string "slippage_model"
    t.datetime "updated_at", null: false
    t.index ["runtime_id"], name: "index_runtime_configs_on_runtime_id"
  end

  create_table "runtimes", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.string "mode"
    t.string "name"
    t.datetime "updated_at", null: false
    t.uuid "uuid"
  end

  create_table "trades", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "executed_at"
    t.bigint "order_id"
    t.decimal "price"
    t.integer "quantity"
    t.bigint "runtime_id"
    t.string "side"
    t.string "symbol"
    t.decimal "trade_value"
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_trades_on_order_id"
    t.index ["runtime_id"], name: "index_trades_on_runtime_id"
  end

  add_foreign_key "accounts", "runtimes"
  add_foreign_key "domain_events", "runtimes"
  add_foreign_key "idempotency_keys", "runtimes"
  add_foreign_key "ledger_entries", "accounts"
  add_foreign_key "ledger_entries", "runtimes"
  add_foreign_key "orders", "accounts"
  add_foreign_key "orders", "runtimes"
  add_foreign_key "paper_execution_queues", "orders"
  add_foreign_key "paper_execution_queues", "runtimes"
  add_foreign_key "paper_funds", "accounts"
  add_foreign_key "paper_funds", "runtimes"
  add_foreign_key "paper_holdings", "accounts"
  add_foreign_key "paper_holdings", "runtimes"
  add_foreign_key "paper_margin_accounts", "accounts"
  add_foreign_key "paper_margin_accounts", "runtimes"
  add_foreign_key "paper_positions", "accounts"
  add_foreign_key "paper_positions", "runtimes"
  add_foreign_key "runtime_configs", "runtimes"
  add_foreign_key "trades", "orders"
  add_foreign_key "trades", "runtimes"
end
