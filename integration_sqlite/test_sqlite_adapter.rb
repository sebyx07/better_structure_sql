#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'config/environment'

puts "=" * 80
puts "Testing SQLite Adapter"
puts "=" * 80

connection = ActiveRecord::Base.connection
adapter = BetterStructureSql::Adapters::Registry.adapter_for(connection)

puts "\n1. Adapter Type:"
puts "   #{adapter.class.name}"

puts "\n2. Database Version:"
puts "   #{adapter.database_version}"

puts "\n3. Fetching Tables:"
tables = adapter.fetch_tables(connection)
puts "   Found #{tables.length} tables:"
tables.each do |table|
  puts "   - #{table[:name]} (#{table[:columns].length} columns)"
end

puts "\n4. Fetching Indexes:"
indexes = adapter.fetch_indexes(connection)
puts "   Found #{indexes.length} indexes:"
indexes.each do |idx|
  puts "   - #{idx[:name]} on #{idx[:table]} (#{idx[:columns].join(', ')})"
end

puts "\n5. Fetching Foreign Keys:"
foreign_keys = adapter.fetch_foreign_keys(connection)
puts "   Found #{foreign_keys.length} foreign keys:"
foreign_keys.each do |fk|
  puts "   - #{fk[:table]}.#{fk[:column]} → #{fk[:foreign_table]}.#{fk[:foreign_column]}"
end

puts "\n6. Fetching Views:"
views = adapter.fetch_views(connection)
puts "   Found #{views.length} views:"
views.each do |view|
  puts "   - #{view[:name]}"
end

puts "\n7. Fetching Triggers:"
triggers = adapter.fetch_triggers(connection)
puts "   Found #{triggers.length} triggers:"
triggers.each do |trigger|
  puts "   - #{trigger[:name]} (#{trigger[:timing]} #{trigger[:event]} on #{trigger[:table_name]})"
end

puts "\n8. Testing SQL Generation:"
if tables.any?
  table = tables.first
  puts "\n   Table SQL for '#{table[:name]}':"
  puts "   " + adapter.generate_table(table).lines.first(5).join("   ")
end

if indexes.any?
  index = indexes.first
  puts "\n   Index SQL:"
  puts "   #{adapter.generate_index(index)}"
end

if views.any?
  view = views.first
  puts "\n   View SQL for '#{view[:name]}':"
  sql = adapter.generate_view(view)
  puts "   " + sql.lines.first(3).join("   ")
end

puts "\n" + "=" * 80
puts "All tests completed successfully!"
puts "=" * 80
