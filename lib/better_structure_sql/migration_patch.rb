# frozen_string_literal: true

module BetterStructureSql
  # Patches ActiveRecord::Migration to handle multi-file schema directories
  #
  # Rails' maintain_test_schema! calls purge_current_test_schema which tries to
  # read the schema file directly using File.read(), which fails when the schema
  # is a directory (multi-file mode).
  #
  # This patch intercepts that behavior and uses our SchemaLoader instead.
  module MigrationPatch
    # Override schema_cache to handle directory-based schemas
    module SchemaCachePatch
      # Returns the schema cache, handling directory-based schemas
      # @return [ActiveRecord::ConnectionAdapters::SchemaCache] Schema cache
      def schema_cache
        return super unless multi_file_schema?

        # For multi-file schemas, we need to handle the cache differently
        # Check if cache exists as a file with the expected naming convention
        cache_path = derived_cache_path

        connection.schema_cache = ActiveRecord::ConnectionAdapters::SchemaCache.load_from(cache_path) if File.exist?(cache_path)

        super
      rescue Errno::EISDIR
        # If we get EISDIR, it means Rails is trying to read a directory
        # This is expected for multi-file schemas, just return the current cache
        connection.schema_cache
      end

      private

      def multi_file_schema?
        return false unless defined?(Rails) && Rails.application

        schema_path = if Rails.application.config.active_record.schema_format == :sql
                        ENV.fetch('SCHEMA', 'db/structure.sql')
                      else
                        'db/schema.rb'
                      end

        full_path = Rails.root.join(schema_path)
        File.directory?(full_path)
      end

      def derived_cache_path
        # Check if using BetterStructureSql config
        base_path = if defined?(BetterStructureSql) && BetterStructureSql.configured?
                      BetterStructureSql.configuration.output_path
                    elsif Rails.application.config.active_record.schema_format == :sql
                      ENV.fetch('SCHEMA', 'db/structure.sql')
                    else
                      'db/schema.rb'
                    end

        # For directory mode, use the directory path + _schema_cache.yml
        if Rails.root.join(base_path).directory?
          Rails.root.join(base_path, '_schema_cache.yml')
        else
          # For file mode, use the default Rails cache path
          Rails.root.join('db/schema_cache.yml')
        end
      end
    end

    # Patch for maintain_test_schema! to handle directory schemas
    module MaintainTestSchemaPatch
      # Maintains test schema, handling directory-based schemas
      # @return [void]
      def maintain_test_schema!
        return super unless should_use_better_structure_sql?

        # Check if we need to load or purge the schema
        if pending_migrations?
          # Purge the schema first
          purge_current_test_schema_with_directory_support
          # Load the schema using our loader
          load_schema_with_directory_support
        end
      rescue Errno::EISDIR
        # If we still get EISDIR, provide a helpful error message
        raise ActiveRecord::MigrationError,
              "Multi-file schema directory detected at #{schema_file_path}. " \
              'Set config.replace_default_load = true in config/initializers/better_structure_sql.rb ' \
              'to enable automatic multi-file schema loading, or run: rails db:schema:load_better'
      end

      private

      def should_use_better_structure_sql?
        return false unless defined?(BetterStructureSql) && defined?(Rails)
        return false unless Rails.application.config.active_record.schema_format == :sql

        # Check if schema path is a directory
        File.directory?(schema_file_path)
      end

      def schema_file_path
        if defined?(BetterStructureSql) && BetterStructureSql.configured?
          Rails.root.join(BetterStructureSql.configuration.output_path)
        else
          Rails.root.join(ENV.fetch('SCHEMA', 'db/structure.sql'))
        end
      end

      def pending_migrations?
        ActiveRecord::Base.connection.migration_context.needs_migration?
      end

      def purge_current_test_schema_with_directory_support
        # Purge the test database
        ActiveRecord::Tasks::DatabaseTasks.purge_current('test')
      rescue ActiveRecord::NoDatabaseError
        # Database doesn't exist, that's fine
      end

      def load_schema_with_directory_support
        if defined?(BetterStructureSql) && BetterStructureSql.configured?
          # Use our loader which handles both files and directories
          loader = BetterStructureSql::SchemaLoader.new(BetterStructureSql.configuration)
          loader.load
        else
          # Fallback to Rails default
          ActiveRecord::Tasks::DatabaseTasks.load_schema_current(:sql)
        end
      end
    end

    # Apply patches when loaded
    def self.apply!
      return unless defined?(ActiveRecord::Migration)

      # Patch maintain_test_schema! if it exists
      ActiveRecord::Migration.singleton_class.prepend(MaintainTestSchemaPatch) if ActiveRecord::Migration.respond_to?(:maintain_test_schema!)

      # Patch schema_cache handling
      return unless defined?(ActiveRecord::MigrationContext)

      ActiveRecord::MigrationContext.prepend(SchemaCachePatch)
    end
  end
end
