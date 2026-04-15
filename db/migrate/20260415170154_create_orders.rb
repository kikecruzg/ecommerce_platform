class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :shipping_address, null: false
      t.decimal :shipping_lat, null: false
      t.decimal :shipping_lng, null: false
      t.string :status, null: false, default: "pending"
      t.decimal :total_amount, null: false
      t.string :payment_id

      t.timestamps
    end

    add_index :orders, :status
  end
end
