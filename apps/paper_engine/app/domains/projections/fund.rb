module Projections
  class Fund < ApplicationRecord
    self.table_name = "paper_funds"
    include RuntimeScoped
    belongs_to :account, class_name: "Accounts::Account"
  end
end
