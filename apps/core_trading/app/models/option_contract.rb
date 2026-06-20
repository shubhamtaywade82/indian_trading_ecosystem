class OptionContract < ApplicationRecord
  belongs_to :derivative_contract
  has_many :option_chain_entries, dependent: :destroy

  validates :strike_price, presence: true, numericality: { greater_than: 0 }
  validates :option_type, presence: true, inclusion: { in: %w[CE PE] }
end
