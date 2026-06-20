module Broker
  class MarginAccount < ApplicationRecord
    self.table_name = "paper_margin_accounts"
    include RuntimeScoped

    belongs_to :account, class_name: "Accounts::Account"
  end
end
