# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, foreign_key: true
      t.decimal :total, precision: 10, scale: 2, null: false
      t.string :status, default: 'pending', null: false

      t.timestamps
    end

    create_table :order_items do |t|
      t.references :order, foreign_key: true
      t.references :product, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :orders, :status
    add_index :order_items, [:order_id, :product_id], unique: true
  end
end
