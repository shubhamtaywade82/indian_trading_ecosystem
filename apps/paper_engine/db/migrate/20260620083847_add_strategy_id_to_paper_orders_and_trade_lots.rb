class AddStrategyIdToPaperOrdersAndTradeLots < ActiveRecord::Migration[7.1]
  def change
    add_column :trade_lots, :strategy_id, :string
  end
end
