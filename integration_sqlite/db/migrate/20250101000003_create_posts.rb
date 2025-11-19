# frozen_string_literal: true

class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.integer :user_id, null: false
      t.string :title, null: false
      t.text :content
      t.string :status, default: 'draft'
      t.text :tags # JSON array stored as TEXT
      t.text :metadata # JSON object stored as TEXT

      t.timestamps
    end

    add_index :posts, :user_id
    add_index :posts, :status

    # Add foreign key inline is not supported in ALTER TABLE
    # We need to recreate the table with foreign key
    execute <<-SQL
      CREATE TABLE posts_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT,
        status TEXT DEFAULT 'draft',
        tags TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    SQL

    execute 'INSERT INTO posts_new SELECT * FROM posts'
    execute 'DROP TABLE posts'
    execute 'ALTER TABLE posts_new RENAME TO posts'

    # Recreate indexes
    add_index :posts, :user_id
    add_index :posts, :status
  end
end
