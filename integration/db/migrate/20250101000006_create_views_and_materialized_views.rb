# frozen_string_literal: true

class CreateViewsAndMaterializedViews < ActiveRecord::Migration[8.1]
  def up
    # Create a regular view
    execute <<~SQL
      CREATE VIEW active_products_view AS
      SELECT
        p.id,
        p.name,
        p.sku,
        p.price,
        p.stock_quantity,
        c.name as category_name,
        p.created_at
      FROM products p
      INNER JOIN categories c ON c.id = p.category_id
      WHERE p.is_active = true
      ORDER BY p.created_at DESC;
    SQL

    # Create another view for user statistics
    execute <<~SQL
      CREATE VIEW user_post_stats AS
      SELECT
        u.id as user_id,
        u.email,
        COUNT(p.id) as total_posts,
        COUNT(p.id) FILTER (WHERE p.published_at IS NOT NULL) as published_posts,
        MAX(p.published_at) as last_published_at
      FROM users u
      LEFT JOIN posts p ON p.user_id = u.id
      GROUP BY u.id, u.email;
    SQL

    # Create a materialized view
    execute <<~SQL
      CREATE MATERIALIZED VIEW product_category_summary AS
      SELECT
        c.id as category_id,
        c.name as category_name,
        COUNT(p.id) as product_count,
        AVG(p.price) as avg_price,
        MIN(p.price) as min_price,
        MAX(p.price) as max_price,
        SUM(p.stock_quantity) as total_stock
      FROM categories c
      LEFT JOIN products p ON p.category_id = c.id AND p.is_active = true
      GROUP BY c.id, c.name;
    SQL

    # Add index to materialized view
    add_index :product_category_summary, :category_id, unique: true
    add_index :product_category_summary, :avg_price
  end

  def down
    execute 'DROP MATERIALIZED VIEW IF EXISTS product_category_summary;'
    execute 'DROP VIEW IF EXISTS user_post_stats;'
    execute 'DROP VIEW IF EXISTS active_products_view;'
  end
end
