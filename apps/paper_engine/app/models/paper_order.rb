class PaperOrder < ApplicationRecord
  include AASM

  belongs_to :account
  has_many :order_status_transitions, dependent: :destroy
  has_many :paper_trades

  validates :instrument_id, presence: true
  validates :side, presence: true, inclusion: { in: %w[buy sell] }
  validates :order_type, presence: true
  validates :product_type, presence: true, inclusion: { in: %w[CNC MIS NRML] }
  validates :qty, presence: true, numericality: { greater_than: 0 }
  validates :client_order_id, presence: true, uniqueness: true

  aasm column: :status do
    state :PENDING, initial: true
    state :OPEN
    state :PARTIALLY_FILLED
    state :FILLED
    state :CANCELLED
    state :REJECTED
    state :EXPIRED

    event :accept do
      transitions from: :PENDING, to: :OPEN
    end

    event :reject do
      transitions from: :PENDING, to: :REJECTED
    end

    event :partial_fill do
      transitions from: [:OPEN, :PARTIALLY_FILLED], to: :PARTIALLY_FILLED
    end

    event :fill do
      transitions from: [:OPEN, :PARTIALLY_FILLED], to: :FILLED
    end

    event :cancel do
      transitions from: [:PENDING, :OPEN, :PARTIALLY_FILLED], to: :CANCELLED
    end

    event :expire do
      transitions from: [:PENDING, :OPEN, :PARTIALLY_FILLED], to: :EXPIRED
    end
  end

  def log_transition(from_status, to_status, reason = nil)
    order_status_transitions.create!(
      from_status: from_status,
      to_status: to_status,
      reason: reason,
      occurred_at: Time.current
    )
  end

  def filled_qty
    paper_trades.sum(:fill_qty)
  end

  def remaining_qty
    qty - filled_qty
  end

  def cancellable?
    PENDING? || OPEN? || PARTIALLY_FILLED?
  end
end
