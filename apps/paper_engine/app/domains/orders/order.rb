module Orders
  class Order < ApplicationRecord
    self.table_name = "orders"
    include RuntimeScoped

    belongs_to :account, class_name: "Accounts::Account"

    include AASM

    aasm column: :status do
      state :pending, initial: true
      state :open
      state :partially_filled
      state :filled
      state :cancelled
      state :rejected
      state :expired

      event :accept do
        transitions from: :pending, to: :open
      end

      event :fill do
        transitions from: [:open, :partially_filled], to: :filled
      end

      event :partial_fill do
        transitions from: :open, to: :partially_filled
      end

      event :cancel do
        transitions from: [:open, :partially_filled], to: :cancelled
      end

      event :reject do
        transitions from: :pending, to: :rejected
      end

      event :expire do
        transitions from: :open, to: :expired
      end
    end
  end
end
