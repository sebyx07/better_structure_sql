# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.integer :post_id
      t.integer :user_id
      t.text :body
      t.integer :parent_id

      t.timestamps
    end

    # Recreate with foreign keys
    execute <<-SQL
      CREATE TABLE comments_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        post_id INTEGER,
        user_id INTEGER,
        body TEXT,
        parent_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
        FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE
      )
    SQL

    execute 'INSERT INTO comments_new SELECT * FROM comments'
    execute 'DROP TABLE comments'
    execute 'ALTER TABLE comments_new RENAME TO comments'

    add_index :comments, :post_id
    add_index :comments, :user_id
    add_index :comments, :parent_id
  end
end
