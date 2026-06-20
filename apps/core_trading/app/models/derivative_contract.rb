class DerivativeContract < ApplicationRecord
  belongs_to :underlying
  has_one :option_contract, dependent: :destroy
  has_one :future_contract, dependent: :destroy

  validates :security_id, presence: true, uniqueness: true
  validates :expiry_date, presence: true
  validates :contract_type, presence: true, inclusion: { in: %w[future call_option put_option] }
end
