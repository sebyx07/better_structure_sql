# frozen_string_literal: true

class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.text :body
      t.references :user, foreign_key: true
      t.string :status, default: 'draft' # Using string instead of ENUM for simplicity

      t.timestamps
    end

    add_index :posts, :status
  end
end
