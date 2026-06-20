class CreateSettlementLots < ActiveRecord::Migration[8.1]
  def change
    create_table :settlement_lots do |t|
      t.bigint :trade_id
      t.string :symbol
      t.decimal :quantity
      t.date :settlement_date
      t.string :status

      t.timestamps
    end
  end
end
