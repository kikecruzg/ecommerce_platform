class Order < ApplicationRecord
  belongs_to :customer
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  enum :status, { pending: "pending", confirmed: "confirmed", failed: "failed" }

  validates :shipping_address, presence: true
  validates :shipping_lat, :shipping_lng, presence: true
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
end
