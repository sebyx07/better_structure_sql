# frozen_string_literal: true

class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false
      t.text :body
      t.datetime :published_at

      t.timestamps
    end

    add_index :posts, :published_at, where: 'published_at IS NOT NULL'
  end
end
