class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :sku, null: false
      t.decimal :price, null: false, precision: 10, scale: 2

      t.timestamps
    end

    add_index :products, :sku, unique: true
  end
end
