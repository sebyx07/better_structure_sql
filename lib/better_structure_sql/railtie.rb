# frozen_string_literal: true

require 'rails/railtie'

module BetterStructureSql
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

        if config.replace_default_dump && !is_ruby_format
          ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(DatabaseTasksExtension)
          ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(DatabaseTasksDumpInfoExtension)
          # Also prepend path override for dump
          ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(DatabaseTasksPathExtension)
        end

        if config.replace_default_load && !is_ruby_format
          ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(DatabaseTasksLoadExtension)
          # Also prepend path override for load
          ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(DatabaseTasksPathExtension)
        end
      end
    end

    # Override schema_dump_path to return our configured path (both dump and load)
    module DatabaseTasksPathExtension
      def schema_dump_path(db_config, format = ActiveRecord.schema_format)
        if format.to_sym == :sql && !BetterStructureSql.configuration.output_path.to_s.end_with?('.rb')
          # Return our configured path for SQL format
          Rails.root.join(BetterStructureSql.configuration.output_path)
        else
          # Use default Rails path for Ruby format
          super
        end
      end
    end

    module DatabaseTasksExtension
      def dump_schema(db_config, format = db_config.schema_format)
        # Only override SQL format dumps
        if format.to_sym == :sql
          return unless db_config.schema_dump

          filename = schema_dump_path(db_config, format)
          return unless filename

          FileUtils.mkdir_p(File.dirname(filename))

          # Call our dumper which already includes schema_migrations
          # Don't auto-store version here - use explicit db:schema:store task
          BetterStructureSql::Dumper.new.dump(store_version: false)
        else
          # For Ruby format, call the original method
          super
        end
      end
    end

    # No longer needed - we override dump_schema instead
    module DatabaseTasksDumpInfoExtension
      # This module is kept for backward compatibility but is no longer used
    end

    module DatabaseTasksLoadExtension
      # Override load_schema to handle both file and directory schemas
      def load_schema(db_config, format = ActiveRecord.schema_format, *_args)
        if format.to_sym == :sql
          # Get the configured schema path (could be file or directory)
          config = BetterStructureSql.configuration
          schema_path = Rails.root.join(config.output_path)

          # Check if schema exists (file or directory)
          abort "#{schema_path} doesn't exist yet. Run `bin/rails db:migrate` to create it, then try again." unless File.exist?(schema_path)

          # Use our loader which handles both file and directory
          loader = BetterStructureSql::SchemaLoader.new(config)
          loader.load
        else
          # For Ruby format, call the original method
          super
        end
      end
    end
  end
end
