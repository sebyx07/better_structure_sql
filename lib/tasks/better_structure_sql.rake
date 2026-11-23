# frozen_string_literal: true

# Clear tasks on reload to avoid duplicate task errors
if defined?(BETTER_STRUCTURE_SQL_TASKS_LOADED)
  %w[
    db:schema:dump_better
    db:schema:load_better
    db:schema:store
    db:schema:versions
    db:schema:cleanup
    db:schema:restore
  ].each do |task_name|
    Rake::Task[task_name].clear if Rake::Task.task_defined?(task_name)
  end
else
  BETTER_STRUCTURE_SQL_TASKS_LOADED = true
end

namespace :db do
  namespace :schema do
    desc 'Dump the database schema to db/structure.sql using BetterStructureSql'
    task dump_better: :environment do
      require 'better_structure_sql'

      dumper = BetterStructureSql::Dumper.new
      output = dumper.dump(store_version: false)

      puts "Schema dumped to #{BetterStructureSql.configuration.output_path}"

      if output.is_a?(Hash)
        # Multi-file mode
        total_files = output.size
        total_size = output.values.sum(&:bytesize)
        puts "Total files: #{total_files}"
        puts "Total size: #{format_bytes(total_size)}"
      else
        # Single-file mode
        puts "Total size: #{format_bytes(output.bytesize)}"
      end
    end

    # Formats byte count as human-readable string
    #
    # @param bytes [Integer] Byte count
    # @return [String] Formatted string (e.g., "1.5 MB")
    def format_bytes(bytes)
      units = %w[B KB MB GB]
      return "#{bytes} B" if bytes < 1024

      exp = (Math.log(bytes) / Math.log(1024)).floor
      exp = [exp, units.length - 1].min
      size = bytes / (1024.0**exp)

      format('%.2f %s', size, units[exp])
    end

    desc 'Load the database schema from db/structure.sql or directory (BetterStructureSql format)'
    task load_better: %i[load_config check_protected_environments] do
      require 'better_structure_sql'

      config = BetterStructureSql.configuration
      loader = BetterStructureSql::SchemaLoader.new(config)

      begin
        loader.load_and_record
      rescue BetterStructureSql::SchemaLoader::LoadError => e
        abort "Error loading schema: #{e.message}"
      end
    end

    desc 'Store current schema as a version in the database'
    task store: :environment do
      require 'better_structure_sql'

      config = BetterStructureSql.configuration
      unless config.enable_schema_versions
        puts 'Schema versioning is not enabled.'
        puts 'Enable it in config/initializers/better_structure_sql.rb:'
        puts '  config.enable_schema_versions = true'
        next
      end

      connection = ActiveRecord::Base.connection
      result = BetterStructureSql::SchemaVersions.store_current(connection)

      if result.skipped?
        puts "\nNo schema changes detected"
        puts "  Current schema matches version ##{result.version_id}"
        puts "  Hash: #{result.hash}"
        puts '  No new version stored'
      else
        version = result.version
        puts "\nStored schema version ##{version.id}"
        puts "  Format: #{version.format_type}"
        puts "  Mode: #{version.output_mode}"
        puts "  Files: #{version.file_count}" if version.multi_file?
        puts "  PostgreSQL: #{version.pg_version}"
        puts "  Size: #{version.formatted_size}"
        puts "  Hash: #{version.content_hash}"
      end
      puts "  Total versions: #{result.total_count}"
    rescue BetterStructureSql::Error => e
      abort "Error storing schema version: #{e.message}"
    end

    desc 'List all stored schema versions'
    task versions: :environment do
      require 'better_structure_sql'

      config = BetterStructureSql.configuration
      unless config.enable_schema_versions
        puts 'Schema versioning is not enabled.'
        puts 'Enable it in config/initializers/better_structure_sql.rb:'
        puts '  config.enable_schema_versions = true'
        next
      end

      versions = BetterStructureSql::SchemaVersions.all_versions
      if versions.empty?
        puts 'No schema versions stored yet'
      else
        puts "\nSchema Versions (#{versions.count} total)\n\n"
        puts 'ID   | Format | Mode        | Files | PostgreSQL | Hash     | Created             | Size'
        puts '-' * 100
        versions.each do |version|
          puts format('%-4d | %-6s | %-11s | %-5s | %-10s | %-8s | %-19s | %s',
                      version.id,
                      version.format_type,
                      version.output_mode,
                      version.file_count || '-',
                      version.pg_version[0..9], # Truncate long version strings
                      version.content_hash[0..7], # First 8 chars of hash
                      version.created_at.strftime('%Y-%m-%d %H:%M:%S'),
                      version.formatted_size)
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
        next
      end

      deleted_count = BetterStructureSql::SchemaVersions.cleanup!
      puts "Deleted #{deleted_count} old version(s)"
      puts "Retained #{BetterStructureSql::SchemaVersions.count} version(s)"
      puts "Retention limit: #{config.schema_versions_limit}"
    end

    desc 'Replace the database schema with a stored version (drops all data; needs CONFIRM=1)'
    task :restore, [:version_id] => %i[environment check_protected_environments] do |_t, args|
      require 'better_structure_sql'

      version_id = args[:version_id] || ENV.fetch('VERSION_ID', nil)
      raise 'Usage: CONFIRM=1 rails db:schema:restore[VERSION_ID]' unless version_id

      version = BetterStructureSql::SchemaVersions.find(version_id)
      raise "Version #{version_id} not found" unless version

      db_config = ActiveRecord::Base.connection_db_config
      unless ENV['CONFIRM'] == '1'
        abort "db:schema:restore replaces the schema of database #{db_config.database}: it drops every table and all data, " \
              "the stored schema versions included, then loads version #{version.id}.\n" \
              "Run it again with CONFIRM=1 to proceed: CONFIRM=1 rails db:schema:restore[#{version.id}]"
      end

      BetterStructureSql::SchemaVersions.restore(version, db_config:)

      puts "Schema version #{version.id} restored into #{db_config.database}"
      puts "  Files: #{version.file_count}" if version.multi_file?
      puts "  Format: #{version.format_type}"
      puts "  PostgreSQL: #{version.pg_version}"
      puts "  Size: #{version.formatted_size}"
    end
  end
end
