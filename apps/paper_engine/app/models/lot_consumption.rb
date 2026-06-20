class LotConsumption < ApplicationRecord
  belongs_to :trade_lot
  belongs_to :closing_trade, class_name: 'PaperTrade'

  validates :qty_consumed, presence: true, numericality: { greater_than: 0 }
  validates :exit_price, presence: true, numericality: { greater_than: 0 }
  validates :realized_pnl, presence: true
  validates :costing_method, presence: true
end
