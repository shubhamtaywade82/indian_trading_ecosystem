class Exchange < ApplicationRecord
  has_many :segments, dependent: :destroy
  has_many :instruments, dependent: :destroy

  validates :code, presence: true, uniqueness: true
end
