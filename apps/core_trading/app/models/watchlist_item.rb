class WatchlistItem < ApplicationRecord
  belongs_to :watchlist
  belongs_to :instrument

  validates :watchlist_id, uniqueness: { scope: :instrument_id }
end
