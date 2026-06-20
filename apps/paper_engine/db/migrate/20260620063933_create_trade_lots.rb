class CreateTradeLots < ActiveRecord::Migration[8.1]
  def change
    create_table :trade_lots do |t|
      t.references :account, null: false, foreign_key: true
      t.string :instrument_id, null: false
      t.references :opening_trade, foreign_key: { to_table: :paper_trades }, null: false
      t.string :side, null: false
      t.integer :original_qty, null: false
      t.integer :remaining_qty, null: false
      t.decimal :entry_price, precision: 16, scale: 4, null: false
      t.string :status, null: false

      t.timestamps
    end

    add_index :trade_lots, :instrument_id
    add_index :trade_lots, :status
  end
end
