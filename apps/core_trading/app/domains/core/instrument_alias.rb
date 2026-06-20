module Core
  class InstrumentAlias < ApplicationRecord
    self.table_name = "core_instrument_aliases"
    belongs_to :instrument, class_name: "Core::Instrument", foreign_key: "core_instrument_id"

    validates :alias_name, presence: true, uniqueness: { scope: :provider }
    validates :provider, presence: true
  end
end
