# frozen_string_literal: true

# This file is for specs that need Rails (controllers, views, integration tests)
ENV['RAILS_ENV'] ||= 'test'

require 'spec_helper'
require 'rails'
require 'action_controller/railtie'
require 'active_record/railtie'
require 'rspec/rails'

# Configure database before Rails initialization
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Minimal Rails app for testing
module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.secret_key_base = 'test'
    config.hosts.clear if config.respond_to?(:hosts)

    # Skip database config file requirement
    config.active_record.database_selector = nil if config.respond_to?(:active_record)
    config.active_record.database_resolver = nil if config.respond_to?(:active_record)
  end
end

# Initialize app before establishing connection
Rails.application = Dummy::Application.new
Rails.application.config.active_record.legacy_connection_handling = false if Rails.application.config.respond_to?(:active_record)

Dummy::Application.initialize!

# Load engine
require_relative '../lib/better_structure_sql/engine'

# Create schema_versions table
ActiveRecord::Schema.define do
  create_table :better_structure_sql_schema_versions, force: true do |t|
    t.text :content, null: false
    t.string :pg_version, null: false
    t.string :format_type, null: false
    t.timestamps
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Clean database between tests
  config.before(:each) do
    BetterStructureSql::SchemaVersion.delete_all
  end
end
