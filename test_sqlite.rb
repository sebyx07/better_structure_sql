#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'active_record'
require 'sqlite3'
require_relative 'lib/better_structure_sql'

# Create temporary SQLite database
db_path = '/tmp/test_sqlite_adapter.db'
File.delete(db_path) if File.exist?(db_path)

# Connect to SQLite
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: db_path
)

connection = ActiveRecord::Base.connection

# Create test schema
puts "Creating test schema..."
connection.execute(<<~SQL)
  CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL,
    name TEXT,
    created_at TEXT NOT NULL
  )
SQL

connection.execute(<<~SQL)
  CREATE TABLE posts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    content TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  )
SQL

connection.execute('CREATE UNIQUE INDEX idx_users_email ON users(email)')
connection.execute('CREATE INDEX idx_posts_user_id ON posts(user_id)')

connection.execute(<<~SQL)
  CREATE VIEW user_post_counts AS
  SELECT users.id, users.email, COUNT(posts.id) as post_count
  FROM users
  LEFT JOIN posts ON users.id = posts.user_id
  GROUP BY users.id, users.email
SQL

connection.execute(<<~SQL)
  CREATE TRIGGER update_user_timestamp
  AFTER UPDATE ON users
  BEGIN
    UPDATE users SET created_at = datetime('now') WHERE id = NEW.id;
  END
SQL

puts "Schema created successfully!"
puts

# Test adapter detection
puts "=" * 80
puts "Testing SQLite Adapter Detection"
puts "=" * 80
adapter = BetterStructureSql::Adapters::Registry.adapter_for(connection)
puts "Adapter class: #{adapter.class.name}"
puts "Database version: #{adapter.database_version}"
puts

# Test introspection
puts "=" * 80
puts "Testing Introspection Methods"
puts "=" * 80

tables = adapter.fetch_tables(connection)
puts "\nTables (#{tables.length}):"
tables.each do |table|
  puts "  - #{table[:name]} (#{table[:columns].length} columns)"
  table[:columns].each do |col|
    puts "    * #{col[:name]}: #{col[:type]} #{col[:nullable] ? 'NULL' : 'NOT NULL'}"
  end
end

indexes = adapter.fetch_indexes(connection)
puts "\nIndexes (#{indexes.length}):"
indexes.each do |idx|
  unique = idx[:unique] ? 'UNIQUE' : ''
  puts "  - #{idx[:name]} #{unique} on #{idx[:table]} (#{idx[:columns].join(', ')})"
end

foreign_keys = adapter.fetch_foreign_keys(connection)
puts "\nForeign Keys (#{foreign_keys.length}):"
foreign_keys.each do |fk|
  puts "  - #{fk[:table]}.#{fk[:column]} → #{fk[:foreign_table]}.#{fk[:foreign_column]}"
  puts "    ON DELETE #{fk[:on_delete]}, ON UPDATE #{fk[:on_update]}"
end

views = adapter.fetch_views(connection)
puts "\nViews (#{views.length}):"
views.each do |view|
  puts "  - #{view[:name]}"
  puts "    Definition: #{view[:definition][0..80]}..."
end

triggers = adapter.fetch_triggers(connection)
puts "\nTriggers (#{triggers.length}):"
triggers.each do |trigger|
  puts "  - #{trigger[:name]} (#{trigger[:timing]} #{trigger[:event]} on #{trigger[:table_name]})"
end

# Test SQL generation
puts
puts "=" * 80
puts "Testing SQL Generation Methods"
puts "=" * 80

if tables.any?
  table = tables[0]
  puts "\nGenerated CREATE TABLE for '#{table[:name]}':"
  puts adapter.generate_table(table)
  puts
end

if indexes.any?
  index = indexes[0]
  puts "Generated CREATE INDEX:"
  puts adapter.generate_index(index)
  puts
end

if views.any?
  view = views[0]
  puts "Generated CREATE VIEW for '#{view[:name]}':"
  puts adapter.generate_view(view)
  puts
end

if triggers.any?
  trigger = triggers[0]
  puts "Generated CREATE TRIGGER for '#{trigger[:name]}':"
  puts adapter.generate_trigger(trigger)
  puts
end

# Test feature support
puts "=" * 80
puts "Testing Feature Support"
puts "=" * 80
puts "Extensions: #{adapter.supports_extensions?}"
puts "Materialized Views: #{adapter.supports_materialized_views?}"
puts "Custom Types: #{adapter.supports_custom_types?}"
puts "Functions: #{adapter.supports_functions?}"
puts "Triggers: #{adapter.supports_triggers?}"
puts "Sequences: #{adapter.supports_sequences?}"
puts "Check Constraints: #{adapter.supports_check_constraints?}"
puts

puts "=" * 80
puts "All SQLite adapter tests completed successfully!"
puts "=" * 80

# Cleanup
connection.disconnect!
File.delete(db_path) if File.exist?(db_path)
