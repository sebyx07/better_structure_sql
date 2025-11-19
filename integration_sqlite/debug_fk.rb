require_relative 'config/environment'

connection = ActiveRecord::Base.connection
adapter = BetterStructureSql::Adapters::Registry.adapter_for(connection)

puts "Adapter class: #{adapter.class.name}"
puts

all_foreign_keys = BetterStructureSql::Introspection.fetch_foreign_keys(connection)
puts "Found #{all_foreign_keys.length} foreign keys:"
all_foreign_keys.each do |fk|
  puts "  - #{fk[:table]}.#{fk[:column]} → #{fk[:foreign_table]}.#{fk[:foreign_column]}"
end
puts

tables = BetterStructureSql::Introspection.fetch_tables(connection)
comments_table = tables.find { |t| t[:name] == 'comments' }

puts "Comments table keys: #{comments_table.keys.inspect}"
puts "Comments table has :foreign_keys key? #{comments_table.key?(:foreign_keys)}"
puts "Comments table[:foreign_keys] = #{comments_table[:foreign_keys].inspect}"
