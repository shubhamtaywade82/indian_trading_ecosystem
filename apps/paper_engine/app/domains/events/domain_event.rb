# frozen_string_literal: true

module Events
  class DomainEvent < ApplicationRecord
    include RuntimeScoped

    self.table_name = "domain_events"
  end
end
