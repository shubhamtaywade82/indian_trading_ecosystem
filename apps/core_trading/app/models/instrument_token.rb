class InstrumentToken < ApplicationRecord
  belongs_to :instrument

  validates :broker, presence: true
  validates :token, presence: true, uniqueness: { scope: :broker }
end
