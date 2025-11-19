require_relative 'config/environment'

connection = ActiveRecord::Base.connection
result = connection.execute("SELECT name, sql FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name != 'schema_migrations' AND name != 'ar_internal_metadata' ORDER BY name")

puts "Raw results:"
result.each_with_index do |row, i|
  puts "Row #{i}: #{row.inspect}"
  puts "  row[0] = #{row[0].inspect}"
  puts "  row[1] = #{row[1].inspect}"
end
