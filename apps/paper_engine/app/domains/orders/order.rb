# frozen_string_literal: true

module Orders
  class Order < ApplicationRecord
    include RuntimeScoped

    self.table_name = "orders"

    belongs_to :account, class_name: "Accounts::Account"
  end
end
