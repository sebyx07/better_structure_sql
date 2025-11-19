# frozen_string_literal: true

class CreateOrdersWithComplexFeatures < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: { on_delete: :restrict }
      t.string :order_number, null: false
      t.column :status, :post_status, null: false, default: 'draft'
      t.decimal :subtotal, precision: 10, scale: 2, null: false, default: 0
      t.decimal :tax_amount, precision: 10, scale: 2, null: false, default: 0
      t.decimal :shipping_cost, precision: 10, scale: 2, null: false, default: 0
      t.decimal :total_amount, precision: 10, scale: 2, null: false, default: 0
      t.jsonb :shipping_address, default: {}
      t.jsonb :billing_address, default: {}
      t.text :notes
      t.timestamp :confirmed_at
      t.timestamp :shipped_at
      t.timestamp :delivered_at
      t.timestamps
    end

    add_index :orders, :order_number, unique: true
    add_index :orders, :status
    add_index :orders, :confirmed_at, where: 'confirmed_at IS NOT NULL'
    add_index :orders, :shipped_at, where: 'shipped_at IS NOT NULL'
    add_index :orders, :created_at

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: { on_delete: :cascade }
      t.references :product, null: false, foreign_key: { on_delete: :restrict }
      t.column :quantity, :positive_integer, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0
      t.decimal :subtotal, precision: 10, scale: 2, null: false
      t.jsonb :product_snapshot, default: {}
      t.timestamps
    end

    add_index :order_items, [:order_id, :product_id], unique: true

    # Add check constraints
    execute <<~SQL
      ALTER TABLE orders
        ADD CONSTRAINT check_order_amounts_positive
        CHECK (subtotal >= 0 AND tax_amount >= 0 AND shipping_cost >= 0 AND total_amount >= 0);
    SQL

    execute <<~SQL
      ALTER TABLE order_items
        ADD CONSTRAINT check_item_amounts_positive
        CHECK (unit_price > 0 AND discount_amount >= 0 AND subtotal >= 0);
    SQL
  end
end
