# frozen_string_literal: true

class JournalEntry < ApplicationRecord
  self.table_name = "journal_entries"

  belongs_to :account
  has_many :ledger_entries, dependent: :destroy
end