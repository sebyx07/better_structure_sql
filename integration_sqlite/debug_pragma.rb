require_relative 'config/environment'

connection = ActiveRecord::Base.connection

puts "Testing PRAGMA index_list with different quoting:"
puts

# Method 1: No quotes
puts "1. PRAGMA index_list(posts):"
begin
  result = connection.execute("PRAGMA index_list(posts)")
  result.each { |row| puts "   #{row.inspect}" }
rescue => e
  puts "   ERROR: #{e.message}"
end
puts

# Method 2: Double quotes (quote_identifier)
puts '2. PRAGMA index_list("posts"):'
begin
  result = connection.execute('PRAGMA index_list("posts")')
  result.each { |row| puts "   #{row.inspect}" }
rescue => e
  puts "   ERROR: #{e.message}"
end
puts

# Check what quote_identifier returns
adapter = BetterStructureSql::Adapters::Registry.adapter_for(connection)
quoted = adapter.send(:quote_identifier, 'posts')
puts "3. quote_identifier('posts') = #{quoted.inspect}"
puts "   PRAGMA index_list(#{quoted}):"
begin
  result = connection.execute("PRAGMA index_list(#{quoted})")
  result.each { |row| puts "   #{row.inspect}" }
rescue => e
  puts "   ERROR: #{e.message}"
end
puts

# Test fetch_indexes
puts "4. Testing adapter.fetch_indexes:"
indexes = adapter.fetch_indexes(connection)
puts "   Found #{indexes.length} indexes"
indexes.each do |idx|
  puts "   - #{idx[:name]} on #{idx[:table]}"
end
