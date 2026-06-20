module Core
  class Instrument < ApplicationRecord
    self.table_name = "core_instruments"

    has_many :aliases, class_name: "Core::InstrumentAlias", foreign_key: "core_instrument_id"
    has_many :option_contracts, class_name: "Core::OptionContract", foreign_key: "core_instrument_id"
    has_many :future_contracts, class_name: "Core::FutureContract", foreign_key: "core_instrument_id"
    has_many :corporate_actions, class_name: "Core::CorporateAction", foreign_key: "core_instrument_id"
    has_many :market_data_snapshots, class_name: "Core::MarketDataSnapshot", foreign_key: "core_instrument_id"

    validates :symbol, presence: true, uniqueness: { scope: :exchange }
    validates :exchange, presence: true
    validates :segment, presence: true
    validates :instrument_type, presence: true
  end
end
