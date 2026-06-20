# frozen_string_literal: true

module Events
  class DomainEvent < ApplicationRecord
    self.table_name = "domain_events"
  end
end
