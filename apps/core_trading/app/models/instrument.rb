class Instrument < ApplicationRecord
  belongs_to :exchange
  belongs_to :segment
  
  has_one :underlying, dependent: :destroy
  has_many :instrument_tokens, dependent: :destroy
  has_many :watchlist_items, dependent: :destroy
  has_many :watchlists, through: :watchlist_items

  enum :instrument_type, {
    equity: "equity",
    index: "index",
    future: "future",
    option: "option",
    currency: "currency",
    commodity: "commodity",
    etf: "etf"
  }, prefix: :type

  validates :security_id, presence: true, uniqueness: true
  validates :symbol, presence: true
end
