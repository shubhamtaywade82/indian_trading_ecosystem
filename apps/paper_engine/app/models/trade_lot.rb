class TradeLot < ApplicationRecord
  belongs_to :account
  belongs_to :opening_trade, class_name: 'PaperTrade'
  has_many :lot_consumptions

  validates :instrument_id, presence: true
  validates :side, presence: true, inclusion: { in: %w[buy sell] }
  validates :original_qty, presence: true, numericality: { greater_than: 0 }
  validates :remaining_qty, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :entry_price, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[OPEN CLOSED] }
end
