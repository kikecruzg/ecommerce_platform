class AddWarehouseToOrders < ActiveRecord::Migration[8.1]
  def change
    add_reference :orders, :warehouse, null: true, foreign_key: true
  end
end
