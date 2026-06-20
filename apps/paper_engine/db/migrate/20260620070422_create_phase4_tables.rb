class CreatePhase4Tables < ActiveRecord::Migration[8.1]
  def change
    create_table :paper_margin_accounts do |t|
      t.references :runtime, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.decimal :cash_balance, default: 0.0
      t.decimal :blocked_margin, default: 0.0
      t.decimal :available_margin, default: 0.0
      t.decimal :utilized_margin, default: 0.0
      t.decimal :mtm_pnl, default: 0.0
      t.decimal :realized_pnl, default: 0.0

      t.timestamps
    end

    create_table :margin_requirements do |t|
      t.string :segment, null: false
      t.string :product_type, null: false
      t.string :symbol
      t.decimal :span_margin_pct, default: 0.0
      t.decimal :exposure_margin_pct, default: 0.0
      t.decimal :cash_requirement_pct, default: 1.0

      t.timestamps
    end
    add_index :margin_requirements, [:segment, :product_type, :symbol], unique: true, name: 'idx_margin_req_lookup'
  end
end
