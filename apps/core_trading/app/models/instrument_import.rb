class InstrumentImport < ApplicationRecord
  validates :source, presence: true
end
