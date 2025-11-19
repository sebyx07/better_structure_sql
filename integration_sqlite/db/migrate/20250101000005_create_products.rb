# frozen_string_literal: true

class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2
      t.integer :stock_quantity, default: 0

      t.timestamps
    end

    add_index :products, :name
  end
end
