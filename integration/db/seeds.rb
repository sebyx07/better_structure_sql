# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts 'Cleaning up existing data...'
if ActiveRecord::Base.connection.table_exists?('events')
  ActiveRecord::Base.connection.execute('TRUNCATE TABLE events, sessions, order_items, orders, product_price_history, posts, products, categories, users RESTART IDENTITY CASCADE')
end

puts 'Creating sample users...'
users = []
users << User.create!(email: 'alice@example.com', encrypted_password: 'password123')
users << User.create!(email: 'bob@example.com', encrypted_password: 'password123')
users << User.create!(email: 'charlie@example.com', encrypted_password: 'password123')
users << User.create!(email: 'david@example.com', encrypted_password: 'password123')
users << User.create!(email: 'eve@example.com', encrypted_password: 'password123')
puts "Created #{users.count} users"

puts 'Creating sample posts...'
posts = []
posts << Post.create!(user: users[0], title: 'Getting Started with Rails', body: 'Rails is a web application framework running on the Ruby programming language.',
                      published_at: 2.days.ago)
posts << Post.create!(user: users[0], title: 'Understanding PostgreSQL', body: 'PostgreSQL is a powerful, open source object-relational database system.', published_at: 1.day.ago)
posts << Post.create!(user: users[1], title: 'Docker for Development', body: 'Docker helps developers build, share, and run applications in containers.', published_at: 3.days.ago)
posts << Post.create!(user: users[1], title: 'Draft Post', body: "This is a draft post that hasn't been published yet.", published_at: nil)
posts << Post.create!(user: users[2], title: 'Ruby Best Practices', body: 'Writing clean, maintainable Ruby code requires following best practices.', published_at: 5.days.ago)
posts << Post.create!(user: users[3], title: 'Advanced PostgreSQL Features', body: 'Learn about JSONB, arrays, and custom types in PostgreSQL.', published_at: 4.days.ago)
puts "Created #{posts.count} posts"

puts 'Creating sample categories...'
categories = []
categories << Category.create!(name: 'Electronics', slug: 'electronics', description: 'Electronic devices and accessories', position: 1)
categories << Category.create!(name: 'Books', slug: 'books', description: 'Physical and digital books', position: 2)
categories << Category.create!(name: 'Clothing', slug: 'clothing', description: 'Apparel and accessories', position: 3)
categories << Category.create!(name: 'Home & Garden', slug: 'home-garden', description: 'Home improvement and gardening', position: 4)

# Create subcategories
electronics_sub = Category.create!(name: 'Smartphones', slug: 'smartphones', description: 'Mobile phones and accessories', parent_id: categories[0].id, position: 1)
books_sub = Category.create!(name: 'Programming', slug: 'programming', description: 'Programming and computer science books', parent_id: categories[1].id, position: 1)
puts "Created #{Category.count} categories"

puts 'Creating sample products...'
products = []

# Electronics products
products << Product.create!(
  category: categories[0],
  name: 'Smartphone X Pro',
  sku: 'PHONE-001',
  description: 'Latest flagship smartphone with advanced features',
  price: 999.99,
  discount_percentage: 10.0,
  stock_quantity: 50,
  is_active: true,
  is_featured: true,
  tags: %w[electronics smartphone flagship],
  metadata: { brand: 'TechCo', warranty: '2 years', color: 'black' },
  specifications: { screen: '6.7 inch OLED', ram: '12GB', storage: '256GB' }
)

products << Product.create!(
  category: electronics_sub,
  name: 'Wireless Earbuds',
  sku: 'AUDIO-001',
  description: 'Premium wireless earbuds with noise cancellation',
  price: 199.99,
  discount_percentage: 15.0,
  stock_quantity: 100,
  is_active: true,
  is_featured: false,
  tags: %w[electronics audio wireless],
  metadata: { brand: 'AudioTech', warranty: '1 year' },
  specifications: { battery_life: '24 hours', drivers: '11mm dynamic' }
)

# Books products
products << Product.create!(
  category: categories[1],
  name: 'The Pragmatic Programmer',
  sku: 'BOOK-001',
  description: 'Your Journey To Mastery, 20th Anniversary Edition',
  price: 49.99,
  discount_percentage: 0,
  stock_quantity: 30,
  is_active: true,
  is_featured: true,
  tags: %w[books programming software-engineering],
  metadata: { author: 'David Thomas, Andrew Hunt', isbn: '978-0135957059', pages: 352 },
  specifications: { format: 'Paperback', language: 'English', publisher: 'Addison-Wesley' }
)

products << Product.create!(
  category: books_sub,
  name: 'Database Internals',
  sku: 'BOOK-002',
  description: 'A Deep Dive into How Distributed Data Systems Work',
  price: 59.99,
  stock_quantity: 20,
  is_active: true,
  is_featured: false,
  tags: %w[books databases distributed-systems],
  metadata: { author: 'Alex Petrov', isbn: '978-1492040347', pages: 373 },
  specifications: { format: 'Paperback', language: 'English' }
)

# Clothing products
products << Product.create!(
  category: categories[2],
  name: 'Classic Cotton T-Shirt',
  sku: 'CLOTH-001',
  description: 'Comfortable 100% cotton t-shirt',
  price: 24.99,
  discount_percentage: 20.0,
  stock_quantity: 200,
  is_active: true,
  is_featured: false,
  tags: %w[clothing casual cotton],
  metadata: { sizes: %w[S M L XL], colors: %w[white black navy] },
  specifications: { material: '100% cotton', care: 'Machine washable' }
)

# Out of stock product
products << Product.create!(
  category: categories[3],
  name: 'Garden Tool Set',
  sku: 'GARDEN-001',
  description: 'Complete 10-piece garden tool set',
  price: 79.99,
  stock_quantity: 0,
  is_active: true,
  is_featured: false,
  tags: %w[garden tools],
  metadata: { pieces: 10, material: 'stainless steel' },
  specifications: { warranty: '5 years' }
)

# Inactive product
products << Product.create!(
  category: categories[0],
  name: 'Old Phone Model',
  sku: 'PHONE-OLD-001',
  description: 'Discontinued phone model',
  price: 299.99,
  stock_quantity: 5,
  is_active: false,
  is_featured: false,
  tags: %w[electronics smartphone discontinued],
  metadata: { brand: 'OldTech' },
  specifications: {}
)

puts "Created #{products.count} products"

puts 'Creating sample orders...'
orders = []

order1 = Order.create!(
  user: users[0],
  order_number: 'ORD-2025-001',
  status: 'published',
  subtotal: 1199.98,
  tax_amount: 96.00,
  shipping_cost: 10.00,
  total_amount: 1305.98,
  shipping_address: {
    street: '123 Main St',
    city: 'San Francisco',
    state: 'CA',
    zip: '94102',
    country: 'USA'
  },
  billing_address: {
    street: '123 Main St',
    city: 'San Francisco',
    state: 'CA',
    zip: '94102',
    country: 'USA'
  },
  confirmed_at: 1.day.ago,
  shipped_at: 12.hours.ago,
  notes: 'Please leave at front door'
)
orders << order1

OrderItem.create!(
  order: order1,
  product: products[0],
  quantity: 1,
  unit_price: 999.99,
  discount_amount: 100.00,
  subtotal: 899.99,
  product_snapshot: products[0].attributes.slice('name', 'sku', 'specifications')
)

OrderItem.create!(
  order: order1,
  product: products[1],
  quantity: 1,
  unit_price: 199.99,
  discount_amount: 30.00,
  subtotal: 169.99,
  product_snapshot: products[1].attributes.slice('name', 'sku', 'specifications')
)

order2 = Order.create!(
  user: users[1],
  order_number: 'ORD-2025-002',
  status: 'draft',
  subtotal: 74.98,
  tax_amount: 6.00,
  shipping_cost: 5.00,
  total_amount: 85.98,
  shipping_address: { street: '456 Oak Ave', city: 'Portland', state: 'OR', zip: '97201', country: 'USA' },
  billing_address: { street: '456 Oak Ave', city: 'Portland', state: 'OR', zip: '97201', country: 'USA' }
)
orders << order2

OrderItem.create!(
  order: order2,
  product: products[4],
  quantity: 3,
  unit_price: 24.99,
  discount_amount: 15.00,
  subtotal: 59.97,
  product_snapshot: products[4].attributes.slice('name', 'sku')
)

puts "Created #{orders.count} orders with #{OrderItem.count} items"

puts 'Creating sample sessions...'
sessions = []
users.each_with_index do |user, index|
  sessions << Session.create!(
    user: user,
    token: SecureRandom.hex(32),
    ip_address: "192.168.1.#{index + 1}",
    user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
    expires_at: 7.days.from_now,
    last_accessed_at: rand(1..60).minutes.ago
  )
end
puts "Created #{sessions.count} sessions"

puts 'Creating sample events...'
event_types = ['user.login', 'user.logout', 'product.view', 'product.purchase', 'cart.add', 'cart.remove']
event_names = ['User Login', 'User Logout', 'Product Viewed', 'Product Purchased', 'Added to Cart', 'Removed from Cart']

50.times do |_i|
  type_index = rand(event_types.length)
  Event.create!(
    user: users.sample,
    event_type: event_types[type_index],
    event_name: event_names[type_index],
    event_data: {
      session_id: sessions.sample.id,
      timestamp: Time.current.to_i,
      user_agent: 'Mozilla/5.0',
      referrer: ['google.com', 'twitter.com', 'direct', nil].sample
    },
    ip_address: "192.168.#{rand(1..255)}.#{rand(1..255)}",
    user_agent: ['Chrome/120.0', 'Safari/17.0', 'Firefox/121.0'].sample,
    occurred_at: rand(1..30).days.ago
  )
end
puts "Created #{Event.count} events"

puts 'Triggering product price change to test audit...'
old_price = products[0].price
products[0].update!(price: 1099.99)
puts "Updated product price from $#{old_price} to $#{products[0].price}"
puts "Price history records: #{ProductPriceHistory.count}"

puts 'Refreshing materialized view...'
ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW product_category_summary')
puts 'Materialized view refreshed'

puts "\nSeed data summary:"
puts "- Users: #{User.count}"
puts "- Posts: #{Post.count} (#{Post.where.not(published_at: nil).count} published)"
puts "- Categories: #{Category.count}"
puts "- Products: #{Product.count} (#{Product.where(is_active: true).count} active)"
puts "- Orders: #{Order.count}"
puts "- Order Items: #{OrderItem.count}"
puts "- Sessions: #{Session.count}"
puts "- Events: #{Event.count}"
puts "- Price History: #{ProductPriceHistory.count}"
puts "\nSeeding complete!"
