# frozen_string_literal: true

class AddCommentsToDatabaseObjects < ActiveRecord::Migration[7.0]
  def up
    # Add table comments
    execute <<-SQL.squish
      COMMENT ON TABLE users IS 'User accounts and authentication data';
    SQL

    execute <<-SQL.squish
      COMMENT ON TABLE posts IS 'Blog posts created by users';
    SQL

    execute <<-SQL.squish
      COMMENT ON TABLE products IS 'Product catalog with pricing and inventory';
    SQL

    # Add column comments
    execute <<-SQL.squish
      COMMENT ON COLUMN users.email IS 'Unique email address for authentication';
    SQL

    execute <<-SQL.squish
      COMMENT ON COLUMN users.encrypted_password IS 'BCrypt hashed password for secure storage';
    SQL

    execute <<-SQL.squish
      COMMENT ON COLUMN posts.title IS 'Post title displayed in search results and feeds';
    SQL

    execute <<-SQL.squish
      COMMENT ON COLUMN posts.content IS 'Full post content in Markdown format';
    SQL

    execute <<-SQL.squish
      COMMENT ON COLUMN products.name IS 'Product name displayed to customers';
    SQL

    execute <<-SQL.squish
      COMMENT ON COLUMN products.price IS 'Current selling price in cents (to avoid floating point errors)';
    SQL

    # Add index comments
    execute <<-SQL.squish
      COMMENT ON INDEX index_users_on_email IS 'Unique index for fast email lookup during authentication';
    SQL

    # Add view comments (if user_posts view exists)
    if view_exists?('user_posts')
      execute <<-SQL.squish
        COMMENT ON VIEW user_posts IS 'Denormalized view joining users with their posts for reporting';
      SQL
    end
  end

  def down
    # Remove table comments
    execute "COMMENT ON TABLE users IS NULL;"
    execute "COMMENT ON TABLE posts IS NULL;"
    execute "COMMENT ON TABLE products IS NULL;"

    # Remove column comments
    execute "COMMENT ON COLUMN users.email IS NULL;"
    execute "COMMENT ON COLUMN users.encrypted_password IS NULL;"
    execute "COMMENT ON COLUMN posts.title IS NULL;"
    execute "COMMENT ON COLUMN posts.content IS NULL;"
    execute "COMMENT ON COLUMN products.name IS NULL;"
    execute "COMMENT ON COLUMN products.price IS NULL;"

    # Remove index comments
    execute "COMMENT ON INDEX index_users_on_email IS NULL;"

    # Remove view comments
    if view_exists?('user_posts')
      execute "COMMENT ON VIEW user_posts IS NULL;"
    end
  end

  private

  def view_exists?(view_name)
    connection.select_value(<<-SQL.squish) > 0
      SELECT COUNT(*)
      FROM pg_catalog.pg_views
      WHERE schemaname = 'public'
      AND viewname = '#{view_name}'
    SQL
  end
end
