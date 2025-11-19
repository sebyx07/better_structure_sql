require_relative 'config/environment'

connection = ActiveRecord::Base.connection
adapter = BetterStructureSql::Adapters::Registry.adapter_for(connection)

puts "Testing fetch_table_names:"
puts

# Call the private method
table_names = adapter.send(:fetch_table_names, connection)
puts "Found #{table_names.length} tables:"
table_names.each { |name| puts "  - #{name}" }
puts

puts "Now testing fetch_indexes with debug output:"
puts

tables = adapter.send(:fetch_table_names, connection)
indexes = []
skip_origins = %w[pk u].freeze

tables.each do |table_name|
  puts "Checking table: #{table_name}"

  index_list = connection.execute("PRAGMA index_list(#{adapter.send(:quote_identifier, table_name)})")
  puts "  Found #{index_list.length} indexes in PRAGMA result"

  index_list.each do |index_row|
    puts "  Index row: #{index_row.inspect}"

    index_name = index_row['name'] || index_row[1]
    is_unique = (index_row['unique'] || index_row[2]).to_i == 1
    origin = index_row['origin'] || index_row[3]

    puts "    name=#{index_name.inspect}, unique=#{is_unique}, origin=#{origin.inspect}"

    if skip_origins.include?(origin)
      puts "    SKIPPED (origin is in #{skip_origins.inspect})"
      next
    end

    puts "    KEEPING this index"
    indexes << { name: index_name, table: table_name }
  end
  puts
end

puts "Total indexes collected: #{indexes.length}"
indexes.each { |idx| puts "  - #{idx[:name]} on #{idx[:table]}" }
