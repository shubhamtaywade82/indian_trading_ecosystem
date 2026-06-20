class Segment < ApplicationRecord
  belongs_to :exchange
  has_many :instruments, dependent: :destroy

  validates :code, presence: true, uniqueness: true
end
