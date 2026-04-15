class WarehouseInventory < ApplicationRecord
  belongs_to :warehouse
  belongs_to :product

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :product_id, uniqueness: { scope: :warehouse_id }

  scope :in_stock, -> { where("quantity > 0") }
end
