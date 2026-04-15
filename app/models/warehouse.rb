class Warehouse < ApplicationRecord
  has_many :warehouse_inventories, dependent: :destroy
  has_many :products, through: :warehouse_inventories
  has_many :orders, dependent: :restrict_with_error

  validates :name, presence: true
  validates :address, presence: true
  validates :latitude, presence: true
  validates :longitude, presence: true
end
