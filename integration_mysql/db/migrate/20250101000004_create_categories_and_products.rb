# frozen_string_literal: true

# MySQL adaptation: No custom types, using inline ENUMs and JSON for complex data
class CreateCategoriesAndProducts < ActiveRecord::Migration[8.1]
  def up
    create_table :categories do |t|
      t.string :name, null: false
      t.text :description
      t.string :slug, null: false

      t.timestamps
    end

    add_index :categories, :slug, unique: true

    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :stock_quantity, null: false, default: 0
      t.references :category, foreign_key: true
      t.json :metadata # MySQL JSON type
      t.json :tags # MySQL doesn't have array types, use JSON

      t.timestamps
    end

    add_index :products, :name
    add_index :products, :price
  end

  def down
    drop_table :products
    drop_table :categories
  end
end
