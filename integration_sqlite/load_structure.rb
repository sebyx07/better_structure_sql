require_relative 'config/environment'

# Drop and recreate
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS better_structure_sql_schema_versions")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS comments")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS posts")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS products")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS users")
ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS user_stats")
ActiveRecord::Base.connection.execute("DROP TRIGGER IF EXISTS update_post_comment_count")
ActiveRecord::Base.connection.execute("DROP TRIGGER IF EXISTS update_posts_updated_at")

# Create schema_migrations
ActiveRecord::Base.connection.execute(<<~SQL)
  CREATE TABLE IF NOT EXISTS schema_migrations (version varchar NOT NULL PRIMARY KEY)
SQL

# Load structure.sql
structure_sql = File.read('db/structure.sql')
# Remove the INSERT statement since we're handling schema_migrations separately
structure_sql = structure_sql.split('-- Schema Migrations').first

# Execute each statement
structure_sql.split(';').each do |statement|
  next if statement.strip.empty?
  next if statement.strip.start_with?('--')

  begin
    ActiveRecord::Base.connection.execute(statement + ';')
  rescue => e
    puts "Error executing: #{statement[0..100]}..."
    puts "  #{e.message}"
  end
end

# Verify FKs
puts "\nVerifying foreign keys on posts table:"
result = ActiveRecord::Base.connection.execute("PRAGMA foreign_key_list(posts)")
result.each do |row|
  puts "  FK: #{row.inspect}"
end

puts "\nChecking CREATE TABLE SQL:"
sql = ActiveRecord::Base.connection.execute("SELECT sql FROM sqlite_master WHERE name='posts'").first
puts sql['sql'] || sql[0]
