# frozen_string_literal: true

require 'rails/railtie'

module BetterStructureSql
  # Rails integration for BetterStructureSql
  #
  # Registers rake tasks, initializers, and optionally replaces
  # default Rails schema dump/load tasks with BetterStructureSql versions.
  class Railtie < Rails::Railtie
    railtie_name :better_structure_sql

    rake_tasks do
      load 'tasks/better_structure_sql.rake'
    end

    initializer 'better_structure_sql.load_config' do
      config_file = Rails.root.join('config/initializers/better_structure_sql.rb')
      load config_file if config_file.exist?
    end

    initializer 'better_structure_sql.replace_default_dump', after: 'active_record.set_configs' do
      ActiveSupport.on_load(:active_record) do
        config = BetterStructureSql.configuration

        # Only replace tasks if using SQL format (structure.sql or directory)
        # If using schema.rb format, silently skip replacement - we can still store versions
        is_ruby_format = config.output_path.to_s.end_with?('.rb')

        # Always apply migration patch for directory schema support in tests
        # This fixes maintain_test_schema! when using multi-file directory mode
        BetterStructureSql::MigrationPatch.apply!

        if config.replace_default_dump && !is_ruby_format
          # Rails copies app config into ActiveRecord before this hook can run, so set both
          Rails.application.config.active_record.schema_format = :sql
          ActiveRecord.schema_format = :sql

          ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(DatabaseTasksPathExtension)
          ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(DatabaseTasksExtension)
        end

        if config.replace_default_load && !is_ruby_format
          ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(DatabaseTasksPathExtension)
          ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(DatabaseTasksLoadExtension)
        end
      end
    end

    # Resolves the schema format Rails would use for a database
    #
    # @param db_config [ActiveRecord::DatabaseConfigurations::DatabaseConfig] Database configuration
    # @param format [Symbol, String, nil] Explicit format, nil for the database's default
    # @return [Symbol] :sql or :ruby
    def self.schema_format_for(db_config, format)
      format ||= db_config.respond_to?(:schema_format) ? db_config.schema_format : ActiveRecord.schema_format
      format.to_sym
    end

    # Extension to override schema_dump_path for BetterStructureSql
    module DatabaseTasksPathExtension
      # Returns the configured output path for the primary database's SQL schema
      #
      # Other databases of a multi-database app keep the path Rails derives from
      # their name, so every database gets its own schema file.
      #
      # @param db_config [ActiveRecord::DatabaseConfigurations::DatabaseConfig] Database configuration
      # @param format [Symbol, nil] Schema format (:sql or :ruby), nil for the database's default
      # @return [Pathname, String, nil] Path to schema file or directory
      def schema_dump_path(db_config, format = nil)
        format = Railtie.schema_format_for(db_config, format)
        return super unless format == :sql && db_config.primary? && db_config.schema_dump(format)
        return super if ENV['SCHEMA']

        Rails.root.join(BetterStructureSql.configuration.output_path)
      end
    end

    # Extension to override DatabaseTasks#dump_schema for SQL format
    module DatabaseTasksExtension
      # Dumps schema using BetterStructureSql for SQL format
      #
      # Each database is dumped through its own connection into its own path.
      #
      # @param db_config [ActiveRecord::DatabaseConfigurations::DatabaseConfig] Database configuration
      # @param format [Symbol, nil] Schema format, nil for the database's default
      # @return [void]
      def dump_schema(db_config, format = nil)
        format = Railtie.schema_format_for(db_config, format)
        return super unless format == :sql

        filename = schema_dump_path(db_config, format)
        return unless filename

        # Don't auto-store version here - use explicit db:schema:store task
        with_temporary_connection(db_config) do |connection|
          BetterStructureSql::Dumper.new(dump_configuration(filename), connection).dump(store_version: false)
        end
      end

      private

      def dump_configuration(filename)
        BetterStructureSql.configuration.dup.tap { |config| config.output_path = filename }
      end
    end

    # Extension to load SQL schemas (single file or multi-file directory) with SchemaLoader
    module DatabaseTasksLoadExtension
      # Rails calls this from load_schema with the database's connection already
      # established, then records the environment and schema checksum itself.
      #
      # @param _configuration [ActiveRecord::DatabaseConfigurations::DatabaseConfig] Database configuration
      # @param filename [String, Pathname] Schema file or directory
      # @return [void]
      def structure_load(_configuration, filename, *)
        BetterStructureSql::SchemaLoader.new(BetterStructureSql.configuration).load(filename)
      end
    end
  end
end
