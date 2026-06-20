# frozen_string_literal: true

class Runtime < ApplicationRecord
  self.table_name = "runtimes"

  has_many :accounts, class_name: "Accounts::Account"
  has_many :orders, class_name: "Orders::Order"
  has_many :trades, class_name: "Trades::Trade"
  has_many :domain_events, class_name: "Events::DomainEvent"
end
