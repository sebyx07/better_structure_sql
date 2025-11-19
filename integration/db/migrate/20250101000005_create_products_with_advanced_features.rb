# frozen_string_literal: true

class CreateProductsWithAdvancedFeatures < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :parent_id
      t.integer :position, default: 0
      t.timestamps
    end

    add_index :categories, :slug, unique: true
    add_index :categories, :parent_id
    add_index :categories, :position
    add_foreign_key :categories, :categories, column: :parent_id, on_delete: :cascade

    create_table :products do |t|
      t.references :category, null: false, foreign_key: { on_delete: :restrict }
      t.string :name, null: false
      t.string :sku, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false
      t.decimal :discount_percentage, precision: 5, scale: 2
      t.integer :stock_quantity, null: false, default: 0
      t.jsonb :metadata, default: {}
      t.jsonb :specifications, default: {}
      t.string :tags, array: true, default: []
      t.boolean :is_active, default: true
      t.boolean :is_featured, default: false
      t.timestamps
    end

    add_index :products, :sku, unique: true
    add_index :products, :name
    add_index :products, :price
    add_index :products, :is_active
    add_index :products, :is_featured, where: 'is_featured = true'
    add_index :products, :metadata, using: :gin
    add_index :products, :specifications, using: :gin
    add_index :products, :tags, using: :gin
    add_index :products, :created_at
    add_index :products, %i[category_id price]

    # Add check constraints
    execute <<~SQL
      ALTER TABLE products
        ADD CONSTRAINT check_price_positive CHECK (price > 0),
        ADD CONSTRAINT check_stock_non_negative CHECK (stock_quantity >= 0),
        ADD CONSTRAINT check_discount_range CHECK (discount_percentage >= 0 AND discount_percentage <= 100);
    SQL
  end
end
