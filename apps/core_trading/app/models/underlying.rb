class Underlying < ApplicationRecord
  belongs_to :instrument
  has_many :derivative_contracts, dependent: :destroy
  has_many :option_chains, dependent: :destroy

  validates :instrument_id, presence: true
end
