module Projections
  class Position < ApplicationRecord
    self.table_name = "paper_positions"
    include RuntimeScoped
    belongs_to :account, class_name: "Accounts::Account"
  end
end
