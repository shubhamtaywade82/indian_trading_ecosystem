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

ActiveRecord::Schema[8.1].define(version: 2026_06_20_063714) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency"
    t.string "name"
    t.bigint "runtime_id", null: false
    t.datetime "updated_at", null: false
    t.index ["runtime_id"], name: "index_accounts_on_runtime_id"
  end

  create_table "domain_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type"
    t.datetime "occurred_at"
    t.jsonb "payload"
    t.bigint "runtime_id", null: false
    t.datetime "updated_at", null: false
    t.index ["runtime_id"], name: "index_domain_events_on_runtime_id"
  end

  create_table "idempotency_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.bigint "resource_id"
    t.string "resource_type"
    t.bigint "runtime_id", null: false
    t.datetime "updated_at", null: false
    t.index ["runtime_id"], name: "index_idempotency_keys_on_runtime_id"
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.string "entry_type"
    t.bigint "reference_id"
    t.string "reference_type"
    t.bigint "runtime_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_ledger_entries_on_account_id"
    t.index ["runtime_id"], name: "index_ledger_entries_on_runtime_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.uuid "external_order_id"
    t.string "order_type"
    t.decimal "price"
    t.integer "quantity"
    t.bigint "runtime_id", null: false
    t.string "side"
    t.string "status"
    t.string "symbol"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_orders_on_account_id"
    t.index ["runtime_id"], name: "index_orders_on_runtime_id"
  end

  create_table "runtime_configs", force: :cascade do |t|
    t.string "brokerage_plan"
    t.datetime "created_at", null: false
    t.string "latency_model"
    t.integer "rng_seed"
    t.bigint "runtime_id", null: false
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
    t.bigint "order_id", null: false
    t.decimal "price"
    t.integer "quantity"
    t.bigint "runtime_id", null: false
    t.string "symbol"
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
  add_foreign_key "runtime_configs", "runtimes"
  add_foreign_key "trades", "orders"
  add_foreign_key "trades", "runtimes"
end
