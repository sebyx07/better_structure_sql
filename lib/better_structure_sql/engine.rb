# frozen_string_literal: true

module BetterStructureSql
  class Engine < ::Rails::Engine
    isolate_namespace BetterStructureSql

    # Set the root to the gem root directory
    # For development with Docker volume mount, the gem is at /
    # In production, this will be the gem's installed location
    config.root = ENV.fetch('BETTER_STRUCTURE_SQL_ROOT', File.expand_path('../../..', __FILE__))

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end

    # No asset pipeline dependencies - we use Bootstrap from CDN
    initializer 'better_structure_sql.assets' do |app|
      # Views and controllers are automatically loaded from app/ directory
      # when using isolate_namespace
    end
  end
end
