class CreatePhase1LedgerFirst < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :tenant_id, null: false
      t.string :mode, null: false # paper, backtest
      t.string :run_id # required for backtest
      t.string :name, null: false
      t.string :currency, default: 'INR'
      
      t.timestamps
    end
    add_index :accounts, [:tenant_id, :mode, :run_id], unique: true

    create_table :paper_orders do |t|
      t.references :account, null: false, foreign_key: true
      t.string :strategy_id
      t.string :instrument_id, null: false
      t.string :side, null: false
      t.string :order_type, null: false
      t.string :product_type, null: false # CNC/MIS/NRML
      t.decimal :qty, null: false
      t.decimal :price
      t.decimal :trigger_price
      t.string :tif, default: 'DAY'
      t.string :status, null: false, default: 'PENDING'
      t.string :client_order_id, null: false
      
      t.timestamps
    end
    add_index :paper_orders, :client_order_id, unique: true
    add_index :paper_orders, [:account_id, :status]

    create_table :order_status_transitions do |t|
      t.references :paper_order, null: false, foreign_key: true
      t.string :from_status
      t.string :to_status, null: false
      t.string :reason
      t.datetime :occurred_at, null: false
      
      t.timestamps
    end

    create_table :paper_trades do |t|
      t.references :paper_order, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :instrument_id, null: false
      t.string :side, null: false
      t.decimal :fill_qty, null: false
      t.decimal :fill_price, null: false
      t.decimal :fill_value, null: false
      t.datetime :exchange_ts, null: false
      t.integer :sequence_no
      t.decimal :slippage_applied, default: 0.0
      
      t.timestamps
    end

    create_table :trade_lots do |t|
      t.references :account, null: false, foreign_key: true
      t.string :instrument_id, null: false
      t.references :opening_trade, null: false, foreign_key: { to_table: :paper_trades }
      t.string :side, null: false
      t.decimal :original_qty, null: false
      t.decimal :remaining_qty, null: false
      t.decimal :entry_price, null: false
      t.string :status, default: 'OPEN' # OPEN, CLOSED
      
      t.timestamps
    end

    create_table :lot_consumptions do |t|
      t.references :trade_lot, null: false, foreign_key: true
      t.references :closing_trade, null: false, foreign_key: { to_table: :paper_trades }
      t.decimal :qty_consumed, null: false
      t.decimal :exit_price, null: false
      t.decimal :realized_pnl, null: false
      t.string :costing_method, null: false
      
      t.timestamps
    end

    create_table :journal_entries do |t|
      t.references :account, null: false, foreign_key: true
      t.string :reference_type, null: false # trade, charge, settlement
      t.bigint :reference_id, null: false
      t.string :description
      
      t.timestamps
    end

    create_table :ledger_entries do |t|
      t.references :account, null: false, foreign_key: true
      t.references :journal_entry, null: false, foreign_key: true
      t.string :ledger_account, null: false # Cash, Inventory:RELIANCE, etc.
      t.decimal :debit, default: 0.0
      t.decimal :credit, default: 0.0
      
      t.timestamps
    end

    create_table :corporate_action_events do |t|
      t.string :instrument_id, null: false
      t.string :action_type, null: false # split, bonus, dividend
      t.decimal :ratio_or_amount, null: false
      t.date :ex_date, null: false
      
      t.timestamps
    end

    create_table :margin_events do |t|
      t.references :account, null: false, foreign_key: true
      t.string :event_type, null: false # block, release, call
      t.decimal :amount, null: false
      t.string :reference_id
      
      t.timestamps
    end

    create_table :paper_configs do |t|
      t.string :scope, null: false
      t.string :key, null: false
      t.jsonb :value, null: false
      
      t.timestamps
    end
    add_index :paper_configs, [:scope, :key], unique: true
  end
end
