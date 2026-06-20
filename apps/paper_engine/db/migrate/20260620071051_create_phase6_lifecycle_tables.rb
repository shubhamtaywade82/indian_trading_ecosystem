class CreatePhase6LifecycleTables < ActiveRecord::Migration[8.1]
  def change
    create_table :charge_profiles do |t|
      t.string :broker, null: false
      t.string :segment, null: false
      t.string :product_type, null: false
      t.decimal :stt_pct, default: 0.0
      t.decimal :gst_pct, default: 0.0
      t.decimal :exchange_pct, default: 0.0
      t.decimal :sebi_pct, default: 0.0
      t.decimal :stamp_pct, default: 0.0
      t.decimal :brokerage_flat, default: 0.0
      t.decimal :brokerage_pct, default: 0.0

      t.timestamps
    end

    create_table :settlement_lots do |t|
      t.references :runtime, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :trade, null: false, foreign_key: { to_table: :trades }
      t.string :symbol, null: false
      t.integer :quantity, null: false
      t.date :settlement_date, null: false
      t.string :status, default: 'PENDING'

      t.timestamps
    end

    create_table :corporate_actions do |t|
      t.references :runtime, null: false, foreign_key: true
      t.string :symbol, null: false
      t.string :action_type, null: false # DIVIDEND, BONUS, SPLIT, etc.
      t.date :ex_date, null: false
      t.date :record_date
      t.jsonb :details, default: {} # e.g. { ratio: '1:5' } or { amount: 20.0 }
      t.string :status, default: 'PENDING'

      t.timestamps
    end

    create_table :portfolio_cashflows do |t|
      t.references :runtime, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :cashflow_type, null: false # DEPOSIT, WITHDRAWAL, DIVIDEND, CHARGES, TAX, SETTLEMENT
      t.decimal :amount, null: false
      t.string :reference_id
      t.string :reference_type

      t.timestamps
    end
  end
end
