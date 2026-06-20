class Watchlist < ApplicationRecord
  has_many :watchlist_items, dependent: :destroy
  has_many :instruments, through: :watchlist_items

  validates :name, presence: true, uniqueness: true
end
