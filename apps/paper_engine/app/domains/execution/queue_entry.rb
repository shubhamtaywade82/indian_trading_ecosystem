module Execution
  class QueueEntry < ApplicationRecord
    self.table_name = "paper_execution_queues"
    include RuntimeScoped

    belongs_to :order, class_name: "Orders::Order"

    # Price priority (buy: highest first, sell: lowest first) and time priority (queue_position asc)
    scope :matching_buys, ->(price) { where(side: 'BUY').where('price >= ?', price).order(price: :desc, queue_position: :asc) }
    scope :matching_sells, ->(price) { where(side: 'SELL').where('price <= ?', price).order(price: :asc, queue_position: :asc) }
  end
end
