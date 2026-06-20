class OrderStatusTransition < ApplicationRecord
  belongs_to :paper_order

  validates :to_status, presence: true
  validates :occurred_at, presence: true
end
