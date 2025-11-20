# frozen_string_literal: true

require 'active_record'
require_relative 'better_structure_sql/version'
require_relative 'better_structure_sql/adapters/base_adapter'
require_relative 'better_structure_sql/adapters/postgresql_config'
require_relative 'better_structure_sql/adapters/registry'
require_relative 'better_structure_sql/configuration'
require_relative 'better_structure_sql/dependency_resolver'
require_relative 'better_structure_sql/introspection'
require_relative 'better_structure_sql/formatter'
require_relative 'better_structure_sql/generators/base'
require_relative 'better_structure_sql/generators/extension_generator'
require_relative 'better_structure_sql/generators/type_generator'
require_relative 'better_structure_sql/generators/sequence_generator'
require_relative 'better_structure_sql/generators/table_generator'
require_relative 'better_structure_sql/generators/index_generator'
require_relative 'better_structure_sql/generators/foreign_key_generator'
require_relative 'better_structure_sql/generators/view_generator'
require_relative 'better_structure_sql/generators/materialized_view_generator'
require_relative 'better_structure_sql/generators/function_generator'
require_relative 'better_structure_sql/generators/trigger_generator'
require_relative 'better_structure_sql/generators/domain_generator'
require_relative 'better_structure_sql/database_version'
require_relative 'better_structure_sql/pg_version'
require_relative 'better_structure_sql/schema_version'
require_relative 'better_structure_sql/store_result'
require_relative 'better_structure_sql/schema_versions'
require_relative 'better_structure_sql/file_writer'
require_relative 'better_structure_sql/manifest_generator'
require_relative 'better_structure_sql/zip_generator'
require_relative 'better_structure_sql/schema_loader'
require_relative 'better_structure_sql/migration_patch'
require_relative 'better_structure_sql/dumper'
require_relative 'better_structure_sql/railtie' if defined?(Rails::Railtie)
require_relative 'better_structure_sql/engine' if defined?(Rails::Engine)

# BetterStructureSql - Clean PostgreSQL schema dumps for Rails applications
#
# Replaces noisy structure.sql files with deterministic, maintainable output
# using pure Ruby database introspection. Supports PostgreSQL, MySQL, and SQLite.
module BetterStructureSql
  # Base error class for all BetterStructureSql errors
  class Error < StandardError; end

  class << self
    attr_writer :configuration

    # Returns the current configuration instance
    #
    # @return [Configuration] The configuration object
    def configuration
      @configuration ||= Configuration.new
    end

    # Configures BetterStructureSql with a block
    #
    # @yield [Configuration] The configuration object
    # @example
    #   BetterStructureSql.configure do |config|
    #     config.output_path = 'db/structure'
    #     config.include_extensions = true
    #   end
    def configure
      yield(configuration)
    end

    # Resets configuration to default values
    #
    # @return [Configuration] A new configuration instance
    def reset_configuration
      @configuration = Configuration.new
    end

    # Check if BetterStructureSql has been configured
    #
    # @return [Boolean] True if configuration has been set
    def configured?
      !@configuration.nil?
    end
  end
end
