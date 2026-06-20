module Core
  class FutureContract < ApplicationRecord
    self.table_name = "core_future_contracts"
    belongs_to :instrument, class_name: "Core::Instrument", foreign_key: "core_instrument_id"

    validates :underlying_symbol, presence: true
    validates :expiry_date, presence: true
  end
end
