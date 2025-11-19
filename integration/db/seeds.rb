# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts 'Creating sample users and posts...'

# Create sample users
user1 = User.find_or_create_by!(email: 'alice@example.com') do |u|
  u.encrypted_password = 'password123'
end

user2 = User.find_or_create_by!(email: 'bob@example.com') do |u|
  u.encrypted_password = 'password123'
end

user3 = User.find_or_create_by!(email: 'charlie@example.com') do |u|
  u.encrypted_password = 'password123'
end

# Create sample posts
Post.find_or_create_by!(user: user1, title: 'Getting Started with Rails') do |p|
  p.body = 'Rails is a web application framework running on the Ruby programming language.'
  p.published_at = 2.days.ago
end

Post.find_or_create_by!(user: user1, title: 'Understanding PostgreSQL') do |p|
  p.body = 'PostgreSQL is a powerful, open source object-relational database system.'
  p.published_at = 1.day.ago
end

Post.find_or_create_by!(user: user2, title: 'Docker for Development') do |p|
  p.body = 'Docker helps developers build, share, and run applications in containers.'
  p.published_at = 3.days.ago
end

Post.find_or_create_by!(user: user2, title: 'Draft Post') do |p|
  p.body = "This is a draft post that hasn't been published yet."
  p.published_at = nil
end

Post.find_or_create_by!(user: user3, title: 'Ruby Best Practices') do |p|
  p.body = 'Writing clean, maintainable Ruby code requires following best practices.'
  p.published_at = 5.days.ago
end

puts "Created #{User.count} users and #{Post.count} posts"
