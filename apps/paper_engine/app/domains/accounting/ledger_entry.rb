# frozen_string_literal: true

module Accounting
  class LedgerEntry < ApplicationRecord
    include RuntimeScoped

    self.table_name = "ledger_entries"

    belongs_to :account, class_name: "Accounts::Account"
  end
end
