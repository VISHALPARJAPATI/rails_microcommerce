class Order < ApplicationRecord
  belongs_to :user

  validates :total_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending completed cancelled failed] }

  scope :pending, -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }
end
