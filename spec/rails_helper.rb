# frozen_string_literal: true

# This file is for specs that need Rails (controllers, views, integration tests)
ENV['RAILS_ENV'] ||= 'test'

require 'spec_helper'
require 'rails'
require 'action_controller/railtie'
require 'active_record/railtie'
require 'rspec/rails'

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
  end
end

# Initialize app
Rails.application = Dummy::Application.new
Dummy::Application.initialize!

# Establish connection
ActiveRecord::Base.establish_connection(:test)

# Load engine
require_relative '../lib/better_structure_sql/engine'

# Create schema_versions table
ActiveRecord::Schema.define do
  create_table :better_structure_sql_schema_versions, force: true do |t|
    t.text :content, null: false
    t.string :pg_version, null: false
    t.string :format_type, null: false
    t.bigint :content_size, null: false
    t.integer :line_count, null: false
    t.timestamps
  end

  add_index :better_structure_sql_schema_versions, :created_at
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Clean database between tests
  config.before do
    BetterStructureSql::SchemaVersion.delete_all
  end
end
