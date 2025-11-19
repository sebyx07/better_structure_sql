# frozen_string_literal: true

module BetterStructureSql
  # Handles loading schema from single file or multi-file directory
  class SchemaLoader
    class LoadError < StandardError; end

    attr_reader :config

    def initialize(config = BetterStructureSql.configuration)
      @config = config
    end

    # Main entry point - auto-detects mode
    # @param path [String, nil] Path to schema file or directory (defaults to config.output_path)
    def load(path = nil)
      path ||= config.output_path
      full_path = Rails.root.join(path)

      if File.directory?(full_path)
        load_directory(full_path)
      elsif File.file?(full_path)
        load_file(full_path)
      else
        raise LoadError, "Schema path not found: #{full_path}"
      end
    end

    private

    def load_directory(dir_path)
      connection = ActiveRecord::Base.connection

      # Load header first
      header_path = File.join(dir_path, '_header.sql')
      connection.execute(File.read(header_path)) if File.exist?(header_path)

      # Load numbered directories in order (01_extensions through 10_migrations)
      # Concatenate all files in each directory and execute as single statement
      # Use [01]* pattern to match directories starting with 0 or 1 (covers 01-10)
      Dir.glob(File.join(dir_path, '[01]*_*')).sort.each do |dir|
        next unless File.directory?(dir)

        dir_name = File.basename(dir)

        # Concatenate all files in this directory
        sql = Dir.glob(File.join(dir, '*.sql')).sort.map { |f| File.read(f) }.join("\n\n")

        # Execute entire directory as single SQL statement
        unless sql.empty?
          connection.execute(sql)
          Rails.logger.debug { "Loaded #{dir_name}" }
        end
      end

      # Read manifest for file count (optional, for logging only)
      manifest_path = File.join(dir_path, '_manifest.json')
      return unless File.exist?(manifest_path)

      manifest = JSON.parse(File.read(manifest_path))
      Rails.logger.debug { "Schema loaded from #{manifest['total_files']} files" }
    end

    def load_file(file_path)
      # Handle schema.rb vs structure.sql
      if file_path.to_s.end_with?('.rb')
        # Use Rails' ActiveRecord::Tasks::DatabaseTasks for .rb files
        # This is what Rails uses internally for db:schema:load
        ActiveRecord::Tasks::DatabaseTasks.load_schema_current(:ruby, file_path)
      else
        # Execute SQL directly for .sql files
        connection = ActiveRecord::Base.connection
        sql = File.read(file_path)
        connection.execute(sql)
      end

      Rails.logger.debug { "Schema loaded from #{file_path}" }
    end
  end
end
