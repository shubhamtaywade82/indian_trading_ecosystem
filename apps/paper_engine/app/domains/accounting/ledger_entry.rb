# frozen_string_literal: true

module Accounting
  class LedgerEntry < ApplicationRecord
    self.table_name = "ledger_entries"
  end
end
