class Candle < ApplicationRecord
  validates :security_id, presence: true
  validates :timeframe, presence: true
  validates :candle_time, presence: true
  validates :open, :high, :low, :close, presence: true, numericality: true
  
  validates :candle_time, uniqueness: { scope: [:security_id, :timeframe] }
end
