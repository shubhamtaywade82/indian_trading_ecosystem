module Core
  class OptionContract < ApplicationRecord
    self.table_name = "core_option_contracts"
    belongs_to :instrument, class_name: "Core::Instrument", foreign_key: "core_instrument_id"

    validates :underlying_symbol, presence: true
    validates :expiry_date, presence: true
    validates :strike_price, presence: true
    validates :option_type, presence: true, inclusion: { in: %w[CE PE] }
  end
end
