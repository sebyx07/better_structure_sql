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
require_relative 'better_structure_sql/schema_versions'
require_relative 'better_structure_sql/file_writer'
require_relative 'better_structure_sql/manifest_generator'
require_relative 'better_structure_sql/zip_generator'
require_relative 'better_structure_sql/schema_loader'
require_relative 'better_structure_sql/dumper'
require_relative 'better_structure_sql/railtie' if defined?(Rails::Railtie)
require_relative 'better_structure_sql/engine' if defined?(Rails::Engine)

module BetterStructureSql
  class Error < StandardError; end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration
      @configuration = Configuration.new
    end
  end
end
