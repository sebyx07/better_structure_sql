# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :encrypted_password
      t.string :uuid, limit: 36
      t.string :role, null: false, default: 'user'

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :uuid

    # Add CHECK constraint for role enum
    execute <<-SQL
      CREATE TABLE users_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        encrypted_password TEXT,
        uuid TEXT,
        role TEXT NOT NULL DEFAULT 'user' CHECK(role IN ('admin', 'user', 'guest')),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    SQL

    execute 'INSERT INTO users_new SELECT * FROM users'
    execute 'DROP TABLE users'
    execute 'ALTER TABLE users_new RENAME TO users'

    # Recreate indexes
    add_index :users, :email, unique: true
    add_index :users, :uuid
  end
end
