class CreatePaperTrades < ActiveRecord::Migration[8.1]
  def change
    create_table :paper_trades do |t|
      t.references :account, null: false, foreign_key: true
      t.references :paper_order, null: false, foreign_key: true
      t.string :instrument_id, null: false
      t.string :side, null: false
      t.integer :fill_qty, null: false
      t.decimal :fill_price, precision: 16, scale: 4, null: false
      t.decimal :fill_value, precision: 16, scale: 4, null: false
      t.datetime :exchange_ts, null: false
      t.integer :sequence_no, null: false
      t.decimal :slippage_applied, precision: 16, scale: 4, default: 0.0

      t.timestamps
    end

    add_index :paper_trades, :instrument_id
    add_index :paper_trades, :sequence_no
  end
end
