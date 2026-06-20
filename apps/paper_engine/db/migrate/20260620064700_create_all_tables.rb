class CreateAllTables < ActiveRecord::Migration[8.1]
  def change
    create_table :runtimes do |t|
      t.string :name
      t.string :mode
      t.uuid :uuid
      t.boolean :active
      t.timestamps
    end

    create_table :runtime_configs do |t|
      t.references :runtime, foreign_key: true
      t.jsonb :settings
      t.timestamps
    end

    create_table :accounts do |t|
      t.references :runtime, foreign_key: true
      t.string :name
      t.string :currency
      t.timestamps
    end

    create_table :orders do |t|
      t.references :runtime, foreign_key: true
      t.references :account, foreign_key: true
      t.string :symbol
      t.string :side
      t.integer :quantity
      t.decimal :price
      t.string :status
      t.timestamps
    end

    create_table :trades do |t|
      t.references :runtime, foreign_key: true
      t.references :order, foreign_key: true
      t.string :symbol
      t.string :side
      t.integer :quantity
      t.decimal :price
      t.decimal :trade_value
      t.datetime :executed_at
      t.timestamps
    end

    create_table :ledger_entries do |t|
      t.references :runtime, foreign_key: true
      t.references :account, foreign_key: true
      t.string :entry_type
      t.string :account_code
      t.decimal :debit, default: 0.0
      t.decimal :credit, default: 0.0
      t.string :reference_type
      t.bigint :reference_id
      t.timestamps
    end

    create_table :domain_events do |t|
      t.references :runtime, foreign_key: true
      t.string :event_type
      t.jsonb :payload
      t.datetime :occurred_at
      t.timestamps
    end

    create_table :idempotency_keys do |t|
      t.references :runtime, foreign_key: true
      t.string :key
      t.timestamps
    end

    create_table :paper_positions do |t|
      t.references :runtime, foreign_key: true
      t.references :account, foreign_key: true
      t.string :symbol
      t.integer :quantity, default: 0
      t.decimal :average_price, default: 0.0
      t.decimal :realized_pnl, default: 0.0
      t.decimal :unrealized_pnl, default: 0.0
      t.timestamps
    end

    create_table :paper_funds do |t|
      t.references :runtime, foreign_key: true
      t.references :account, foreign_key: true
      t.decimal :cash_balance, default: 0.0
      t.decimal :blocked_balance, default: 0.0
      t.decimal :available_balance, default: 0.0
      t.timestamps
    end

    create_table :paper_holdings do |t|
      t.references :runtime, foreign_key: true
      t.references :account, foreign_key: true
      t.string :symbol
      t.integer :quantity, default: 0
      t.decimal :average_price, default: 0.0
      t.timestamps
    end
  end
end
