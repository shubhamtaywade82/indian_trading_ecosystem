class CreatePhase5RiskTables < ActiveRecord::Migration[8.1]
  def change
    create_table :strategies do |t|
      t.references :runtime, null: false, foreign_key: true
      t.string :name, null: false
      t.string :code, null: false
      t.string :status, default: 'ACTIVE'

      t.timestamps
    end

    create_table :risk_profiles do |t|
      t.references :runtime, null: false, foreign_key: true
      t.references :strategy, null: true, foreign_key: true # null for portfolio-level
      t.decimal :max_daily_loss
      t.decimal :max_drawdown_pct
      t.decimal :max_position_size
      t.integer :max_open_positions
      t.decimal :max_symbol_exposure_pct
      t.decimal :max_sector_exposure_pct

      t.timestamps
    end

    create_table :paper_risk_snapshots do |t|
      t.references :runtime, null: false, foreign_key: true
      t.references :strategy, null: true, foreign_key: true
      t.decimal :portfolio_value, default: 0.0
      t.decimal :equity, default: 0.0
      t.decimal :peak_equity, default: 0.0
      t.decimal :drawdown_pct, default: 0.0
      t.decimal :daily_pnl, default: 0.0
      t.integer :open_positions, default: 0
      t.jsonb :sector_exposure, default: {}
      t.jsonb :symbol_exposure, default: {}
      t.date :snapshot_date

      t.timestamps
    end

    add_column :orders, :strategy_id, :bigint
    add_foreign_key :orders, :strategies
  end
end
