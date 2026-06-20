class CreatePaperRiskProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :paper_risk_profiles do |t|
      t.string :account_id
      t.string :strategy_id
      t.decimal :max_daily_loss
      t.decimal :max_drawdown_pct
      t.decimal :max_position_size
      t.integer :max_open_positions
      t.decimal :max_symbol_exposure_pct
      t.string :status

      t.timestamps
    end
  end
end
