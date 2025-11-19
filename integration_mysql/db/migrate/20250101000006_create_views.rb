# frozen_string_literal: true

# MySQL adaptation: Views only (no materialized views)
class CreateViews < ActiveRecord::Migration[8.1]
  def up
    # Create a simple view for user post counts
    execute <<~SQL
      CREATE VIEW user_post_counts AS
      SELECT
        users.id AS user_id,
        users.email,
        COUNT(posts.id) AS post_count
      FROM users
      LEFT JOIN posts ON posts.user_id = users.id
      GROUP BY users.id, users.email;
    SQL

    # Create view for product inventory
    execute <<~SQL
      CREATE VIEW product_inventory AS
      SELECT
        products.id,
        products.name,
        products.price,
        products.stock_quantity,
        categories.name AS category_name
      FROM products
      JOIN categories ON categories.id = products.category_id
      WHERE products.stock_quantity > 0;
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS product_inventory;'
    execute 'DROP VIEW IF EXISTS user_post_counts;'
  end
end
