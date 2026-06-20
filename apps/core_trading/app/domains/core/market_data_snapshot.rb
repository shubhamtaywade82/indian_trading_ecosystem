module Core
  class MarketDataSnapshot < ApplicationRecord
    self.table_name = "core_market_data_snapshots"
    belongs_to :instrument, class_name: "Core::Instrument", foreign_key: "core_instrument_id"
  end
end
