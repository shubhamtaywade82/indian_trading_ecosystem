class OptionChain < ApplicationRecord
  belongs_to :underlying
  has_many :option_chain_entries, dependent: :destroy

  validates :expiry, presence: true
  validates :snapshot_at, presence: true
end
