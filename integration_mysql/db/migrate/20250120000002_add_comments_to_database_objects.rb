# frozen_string_literal: true

class AddCommentsToDatabaseObjects < ActiveRecord::Migration[7.0]
  def up
    # Add table comments using ALTER TABLE COMMENT
    execute "ALTER TABLE users COMMENT 'User accounts and authentication data'"
    execute "ALTER TABLE posts COMMENT 'Blog posts created by users'"
    execute "ALTER TABLE categories COMMENT 'Product and content categories for organization'"
    execute "ALTER TABLE products COMMENT 'Product catalog with pricing and inventory'"
    execute "ALTER TABLE orders COMMENT 'Customer orders with order items'"

    # Note: MySQL column comments require full column definition with MODIFY COLUMN
    # This is more complex as we'd need to fetch the current column type
    # For demonstration, we'll show the syntax in comments

    # Example column comment syntax (would need actual column types):
    # execute "ALTER TABLE users MODIFY COLUMN email VARCHAR(255) NOT NULL COMMENT 'Unique email address for authentication'"
    # execute "ALTER TABLE users MODIFY COLUMN encrypted_password VARCHAR(255) NOT NULL COMMENT 'BCrypt hashed password for secure storage'"
    # execute "ALTER TABLE posts MODIFY COLUMN title VARCHAR(255) NOT NULL COMMENT 'Post title displayed in search results'"
    # execute "ALTER TABLE posts MODIFY COLUMN content TEXT COMMENT 'Full post content in Markdown format'"
    # execute "ALTER TABLE products MODIFY COLUMN name VARCHAR(255) NOT NULL COMMENT 'Product name displayed to customers'"
    # execute "ALTER TABLE products MODIFY COLUMN price DECIMAL(10,2) NOT NULL COMMENT 'Current selling price in dollars'"

    # MySQL doesn't support comments on indexes, views, or functions
  end

  def down
    # Remove table comments
    execute "ALTER TABLE users COMMENT ''"
    execute "ALTER TABLE posts COMMENT ''"
    execute "ALTER TABLE categories COMMENT ''"
    execute "ALTER TABLE products COMMENT ''"
    execute "ALTER TABLE orders COMMENT ''"

    # Column comments would be removed similarly with MODIFY COLUMN
  end
end
