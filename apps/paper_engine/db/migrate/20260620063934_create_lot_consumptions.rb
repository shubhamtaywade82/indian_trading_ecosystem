class CreateLotConsumptions < ActiveRecord::Migration[8.1]
  def change
    create_table :lot_consumptions do |t|
      t.references :trade_lot, null: false, foreign_key: true
      t.references :closing_trade, foreign_key: { to_table: :paper_trades }, null: false
      t.integer :qty_consumed, null: false
      t.decimal :exit_price, precision: 16, scale: 4, null: false
      t.decimal :realized_pnl, precision: 16, scale: 4, default: 0.0
      t.string :costing_method

      t.timestamps
    end
  end
end
