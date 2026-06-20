class PaperTrade < ApplicationRecord
  belongs_to :paper_order
  belongs_to :account
  has_many :trade_lots, foreign_key: :opening_trade_id
  has_many :lot_consumptions, foreign_key: :closing_trade_id

  validates :instrument_id, presence: true
  validates :side, presence: true, inclusion: { in: %w[buy sell] }
  validates :fill_qty, presence: true, numericality: { greater_than: 0 }
  validates :fill_price, presence: true, numericality: { greater_than: 0 }
  validates :fill_value, presence: true, numericality: { greater_than: 0 }
  validates :exchange_ts, presence: true
end
