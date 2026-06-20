class PositionTracker < ApplicationRecord
  enum :status, { pending: 0, active: 1, exited: 2, cancelled: 3 }

  scope :live, -> { where(paper: false) }
  scope :paper, -> { where(paper: true) }
  scope :active_positions, -> { where(status: :active) }
  scope :open, -> { where(status: [:pending, :active]) }

  def to_domain
    DomainModels::PositionTracker.new(attributes.symbolize_keys)
  end

  def to_h
    attributes.symbolize_keys
  end

  def from_domain(domain_tracker)
    assign_attributes(domain_tracker.to_h)
    save!
  end
end