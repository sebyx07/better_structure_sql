# frozen_string_literal: true

class CreateAdvancedIndexes < ActiveRecord::Migration[8.1]
  def change
    # Expression indexes
    add_index :users, 'LOWER(email)', name: 'index_users_on_lower_email'
    add_index :products, '(price * (1 - COALESCE(discount_percentage, 0) / 100))',
              name: 'index_products_on_discounted_price'
    add_index :categories, 'LOWER(name)', name: 'index_categories_on_lower_name'

    # Composite indexes with WHERE clauses
    add_index :products, %i[category_id is_active price],
              where: 'is_active = true AND stock_quantity > 0',
              name: 'index_products_on_available_items'

    # GIN indexes for JSONB search
    execute <<~SQL
      CREATE INDEX index_products_metadata_path
        ON products USING gin (metadata jsonb_path_ops);
    SQL

    execute <<~SQL
      CREATE INDEX index_orders_shipping_address_path
        ON orders USING gin (shipping_address jsonb_path_ops);
    SQL

    # Full-text search index (GIN)
    execute <<~SQL
      CREATE INDEX index_products_fulltext_search
        ON products USING gin (
          to_tsvector('english', COALESCE(name, '') || ' ' || COALESCE(description, ''))
        );
    SQL

    # BRIN index for time-series data (efficient for large tables with natural ordering)
    execute <<~SQL
      CREATE INDEX index_orders_created_at_brin
        ON orders USING brin (created_at);
    SQL

    # Partial unique index
    add_index :products, :sku,
              where: 'is_active = true',
              unique: true,
              name: 'index_active_products_unique_sku'
  end
end
