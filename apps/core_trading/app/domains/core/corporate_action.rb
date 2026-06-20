module Core
  class CorporateAction < ApplicationRecord
    self.table_name = "core_corporate_actions"
    belongs_to :instrument, class_name: "Core::Instrument", foreign_key: "core_instrument_id"

    validates :action_type, presence: true
    validates :ex_date, presence: true
  end
end
