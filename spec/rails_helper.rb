# frozen_string_literal: true

# This file is for specs that need Rails (controllers, views, integration tests)
ENV['RAILS_ENV'] ||= 'test'

require 'spec_helper'
require 'rails'
require 'action_controller/railtie'
require 'active_record/railtie'
require 'rspec/rails'
require 'rails-controller-testing'
require 'database_cleaner/active_record'
require 'factory_bot_rails'

# Minimal Rails app for testing
module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.secret_key_base = 'test'
    config.hosts.clear if config.respond_to?(:hosts)
    config.active_record.check_schema_cache_dump_version = false
    config.root = File.expand_path('../..', __dir__)
    config.paths.add 'config/database', with: 'config/database.yml'
    # Add engine views path
    config.paths['app/views'].unshift File.expand_path('../app/views', __dir__)
  end
end

# Initialize app
Rails.application = Dummy::Application.new
Dummy::Application.initialize!

# Establish connection
ActiveRecord::Base.establish_connection(:test)

# Load engine
require_relative '../lib/better_structure_sql/engine'

# Load helpers first (before controllers that may reference them)
Dir[File.expand_path('../app/helpers/**/*.rb', __dir__)].sort.each { |f| require f }

# Load engine controllers, models, and routes
Dir[File.expand_path('../app/controllers/**/*.rb', __dir__)].sort.each { |f| require f }
Dir[File.expand_path('../app/models/**/*.rb', __dir__)].sort.each { |f| require f }
require_relative '../config/routes'

# Create schema_versions table
ActiveRecord::Schema.define do
  create_table :better_structure_sql_schema_versions, force: true do |t|
    t.text :content, null: false
    t.binary :zip_archive, null: true
    t.string :pg_version, null: false
    t.string :format_type, null: false
    t.string :output_mode, null: false
    t.bigint :content_size, null: false
    t.integer :line_count, null: false
    t.integer :file_count, null: true
    t.timestamps
  end

  add_index :better_structure_sql_schema_versions, :created_at, order: { created_at: :desc }
  add_index :better_structure_sql_schema_versions, :output_mode
end

RSpec.configure do |config|
  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Database Cleaner configuration
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do |example|
    # Use truncation for controller specs, transaction for others
    DatabaseCleaner.strategy = example.metadata[:type] == :controller ? :truncation : :transaction
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
