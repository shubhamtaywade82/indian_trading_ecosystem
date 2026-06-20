class CreatePhase9StrategyTables < ActiveRecord::Migration[8.1]
  def change
    add_column :strategies, :strategy_type, :string, default: 'LONG_TERM'
    add_column :strategies, :version, :string, default: '1.0'
    add_column :strategies, :code_ref, :string
    add_column :strategies, :config, :jsonb, default: {}

    create_table :investment_mandates do |t|
      t.references :strategy, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :target_return
      t.string :horizon
      t.decimal :risk_budget
      t.decimal :capital_allocation
      t.string :rebalance_frequency
      t.decimal :max_drawdown
      t.jsonb :allowed_segments, default: []

      t.timestamps
    end

    create_table :signals do |t|
      t.references :strategy, null: false, foreign_key: true
      t.references :investment_mandate, null: false, foreign_key: true
      t.string :symbol, null: false
      t.string :action, null: false
      t.string :status, default: 'GENERATED'
      t.decimal :confidence
      t.decimal :score
      t.decimal :entry_price
      t.decimal :stop_loss
      t.decimal :target_price
      t.string :time_horizon
      t.text :reasoning

      t.timestamps
    end

    create_table :portfolio_allocations do |t|
      t.references :runtime, null: false, foreign_key: true
      t.string :name, null: false
      t.jsonb :target_weights, default: {}
      t.jsonb :actual_weights, default: {}
      t.decimal :cash_allocation

      t.timestamps
    end
  end
end
