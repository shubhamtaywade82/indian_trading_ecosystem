# frozen_string_literal: true

module Trades
  class Trade < ApplicationRecord
    include RuntimeScoped

    self.table_name = "trades"

    belongs_to :order, class_name: "Orders::Order"
  end
end
