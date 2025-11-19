# frozen_string_literal: true

namespace :db do
  namespace :schema do
    desc 'Dump the database schema to db/structure.sql using BetterStructureSql'
    task dump_better: :environment do
      require 'better_structure_sql'

      dumper = BetterStructureSql::Dumper.new
      output = dumper.dump

      puts "Schema dumped to #{BetterStructureSql.configuration.output_path}"
      puts "Total size: #{output.bytesize} bytes"
    end

    desc 'Load the database schema from db/structure.sql (BetterStructureSql format)'
    task load_better: [:load_config, :check_protected_environments] do
      config = BetterStructureSql.configuration
      structure_file = Rails.root.join(config.output_path)

      unless File.exist?(structure_file)
        puts "Schema file not found: #{structure_file}"
        exit 1
      end

      # Clean the file: remove Rails' appended duplicate INSERT if present
      content = File.read(structure_file)
      # Remove everything after the last ON CONFLICT DO NOTHING;
      clean_content = content.sub(/ON CONFLICT DO NOTHING;.*\z/m, "ON CONFLICT DO NOTHING;\n")

      # Execute SQL directly using ActiveRecord connection
      connection = ActiveRecord::Base.connection
      connection.execute("SET client_min_messages TO warning")

      # Execute the cleaned SQL
      connection.execute(clean_content)

      puts "Schema loaded from #{structure_file}"
    end

    desc 'Store current schema as a version in the database'
    task store: :environment do
      require 'better_structure_sql'

      unless BetterStructureSql.configuration.enable_schema_versions
        puts 'Schema versioning is not enabled.'
        puts 'Enable it in config/initializers/better_structure_sql.rb:'
        puts '  config.enable_schema_versions = true'
        exit 1
      end

      version = BetterStructureSql::SchemaVersions.store_current
      if version
        puts 'Schema version stored successfully'
        puts "  ID: #{version.id}"
        puts "  Format: #{version.format_type}"
        puts "  PostgreSQL: #{version.pg_version}"
        puts "  Size: #{version.formatted_size}"
        puts "  Total versions: #{BetterStructureSql::SchemaVersions.count}"
      else
        puts 'No schema file found to store'
        exit 1
      end
    end

    desc 'List all stored schema versions'
    task versions: :environment do
      require 'better_structure_sql'

      unless BetterStructureSql.configuration.enable_schema_versions
        puts 'Schema versioning is not enabled.'
        exit 1
      end

      versions = BetterStructureSql::SchemaVersions.all_versions
      if versions.empty?
        puts 'No schema versions stored yet'
      else
        puts "Total versions: #{versions.count}"
        puts "\nID     Format       PostgreSQL      Created              Size"
        puts '-' * 80
        versions.each do |version|
          puts format('%-6d %-12s %-15s %-20s %s', version.id, version.format_type, version.pg_version,
                      version.created_at.strftime('%Y-%m-%d %H:%M:%S'), version.formatted_size)
        end
      end
    end

    desc 'Cleanup old schema versions based on retention limit'
    task cleanup: :environment do
      require 'better_structure_sql'

      unless BetterStructureSql.configuration.enable_schema_versions
        puts 'Schema versioning is not enabled.'
        exit 1
      end

      config = BetterStructureSql.configuration
      if config.schema_versions_limit.zero?
        puts 'Retention limit is set to unlimited (0). No cleanup needed.'
        exit 0
      end

      deleted_count = BetterStructureSql::SchemaVersions.cleanup!
      puts "Deleted #{deleted_count} old version(s)"
      puts "Retained #{BetterStructureSql::SchemaVersions.count} version(s)"
      puts "Retention limit: #{config.schema_versions_limit}"
    end
  end
end
