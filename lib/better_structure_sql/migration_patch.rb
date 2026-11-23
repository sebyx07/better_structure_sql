# frozen_string_literal: true

module BetterStructureSql
  # Patches ActiveRecord so a multi-file schema directory works where Rails expects a file
  module MigrationPatch
    # Keeps the test schema current for a schema directory Rails does not know about
    #
    # With replace_default_dump or replace_default_load on, Rails resolves the
    # directory itself (schema_dump_path) and its own maintain_test_schema! works
    # unchanged. Otherwise Rails looks at db/structure.sql, so the directory at
    # config.output_path is loaded here, through the same Rails calls.
    module MaintainTestSchemaPatch
      # Reloads the test database when the schema directory changed, then fails on pending migrations
      # @return [void]
      def maintain_test_schema!
        return super unless ActiveRecord.maintain_test_schema && unmanaged_schema_directory?

        db_config = ActiveRecord::Base.connection_db_config
        tasks = ActiveRecord::Tasks::DatabaseTasks
        load_schema_directory(tasks, db_config) unless tasks.schema_up_to_date?(db_config, :sql, schema_directory)
        check_pending_migrations
      end

      private

      def unmanaged_schema_directory?
        config = BetterStructureSql.configuration
        return false if config.replace_default_dump || config.replace_default_load

        ActiveRecord.schema_format == :sql && File.directory?(schema_directory)
      end

      def schema_directory
        Rails.root.join(BetterStructureSql.configuration.output_path).to_s
      end

      # load_schema records the environment and the schema checksum in ar_internal_metadata
      def load_schema_directory(tasks, db_config)
        tasks.purge(db_config)
        ActiveRecord::Base.establish_connection(db_config)
        tasks.load_schema(db_config, :sql, schema_directory)
      end
    end

    # Patch for DatabaseTasks to handle directory schemas in development
    module DatabaseTasksPatch
      # Override check_schema_file to handle directories
      # @param filename [String] Path to schema file or directory
      # @return [void]
      def check_schema_file(filename)
        # For directory mode, check if directory exists
        if File.directory?(filename)
          return if Dir.glob(File.join(filename, '**', '*.sql')).any?

          message = "#{filename} exists but contains no SQL files. Run `bin/rails db:migrate` to create schema files."
          Kernel.abort message
        end

        # For file mode, use default Rails behavior
        super
      end

      # Loads a schema directory with SchemaLoader: the database's command line client only loads a file
      # @param db_config [ActiveRecord::DatabaseConfigurations::DatabaseConfig] Database configuration
      # @param filename [String, Pathname] Schema file or directory
      # @return [void]
      def structure_load(db_config, filename, *)
        return super unless File.directory?(filename)

        BetterStructureSql::SchemaLoader.new.load(filename)
      end

      # Override schema_sha1 to handle directories
      # @param file [String] Path to schema file or directory
      # @return [String] SHA1 checksum
      def schema_sha1(file)
        return super unless File.directory?(file)

        BetterStructureSql::SchemaLoader.schema_sha1(file)
      end
    end

    # Apply patches when loaded
    def self.apply!
      return unless defined?(ActiveRecord::Migration)

      # Patch maintain_test_schema! if it exists
      ActiveRecord::Migration.singleton_class.prepend(MaintainTestSchemaPatch) if ActiveRecord::Migration.respond_to?(:maintain_test_schema!)

      # Patch DatabaseTasks for development/production use
      return unless defined?(ActiveRecord::Tasks::DatabaseTasks)

      ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(DatabaseTasksPatch)
    end
  end
end
