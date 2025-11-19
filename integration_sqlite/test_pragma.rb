require_relative 'config/environment'

connection = ActiveRecord::Base.connection

puts "Testing PRAGMA table_info:"
result = connection.execute("PRAGMA table_info(users)")
puts "First row: #{result.first.inspect}"
puts "Is hash? #{result.first.is_a?(Hash)}"

puts "\nTesting PRAGMA index_list:"
result2 = connection.execute("PRAGMA index_list(users)")
puts "First row: #{result2.first.inspect}" if result2.any?
