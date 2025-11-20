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

      # Load numbered directories in order (01_extensions through 20_migrations)
      # Load all files in each directory and execute statements
      # Use [012]* pattern to match directories starting with 0, 1, or 2 (covers 01-29)
      Dir.glob(File.join(dir_path, '[012]*_*')).sort.each do |dir|
        next unless File.directory?(dir)

        dir_name = File.basename(dir)

        # Process files in this directory
        Dir.glob(File.join(dir, '*.sql')).sort.each do |file_path|
          sql_content = File.read(file_path)
          next if sql_content.strip.empty?

          # Execute SQL (connection.execute can handle multiple statements for SQLite)
          execute_sql_statements(connection, sql_content)
        end

        Rails.logger.debug { "Loaded #{dir_name}" }
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
        execute_sql_statements(connection, sql)
      end

      Rails.logger.debug { "Schema loaded from #{file_path}" }
    end

    # Execute SQL statements, handling adapter-specific multi-statement behavior
    def execute_sql_statements(connection, sql)
      adapter_name = connection.adapter_name.downcase

      case adapter_name
      when 'sqlite'
        # SQLite's ActiveRecord execute() uses prepare() which can't handle multiple statements
        # We need to use the raw database connection's execute_batch method
        connection.raw_connection.execute_batch(sql)
      when 'postgresql', 'postgis'
        # PostgreSQL can handle multiple statements in one execute call
        connection.execute(sql)
      when 'mysql', 'mysql2', 'trilogy'
        # MySQL needs statements executed individually
        execute_mysql_statements(connection, sql)
      else
        # Fallback: Try executing as-is first
        begin
          connection.execute(sql)
        rescue StandardError
          # If that fails, split by semicolon and execute individually
          sql.split(/;\\s*$/).each do |statement|
            next if statement.strip.empty?

            connection.execute("#{statement};")
          end
        end
      end
    end

    def execute_mysql_statements(connection, sql)
      # Split SQL into individual statements for MySQL
      # MySQL can't execute multiple statements in one call via ActiveRecord normally.
      # For procedures/triggers with BEGIN/END blocks, we need special handling.

      # Split into statements, respecting BEGIN/END blocks
      statements = []
      current_statement = +'' # Unfreeze string with unary plus
      in_block = false # Track if we're inside a BEGIN/END block

      sql.each_line do |line|
        # Skip standalone comment lines
        next if line.strip.start_with?('--') && current_statement.strip.empty?

        current_statement << line

        # Track BEGIN/END blocks (procedures and triggers)
        # MySQL procedures: CREATE PROCEDURE name(...) BEGIN ... END;
        # MySQL triggers: CREATE TRIGGER ... FOR EACH ROW BEGIN ... END;
        stripped_line = line.strip.upcase

        # Detect start of block: "BEGIN" on its own line or "FOR EACH ROW BEGIN"
        in_block = true if stripped_line == 'BEGIN' || stripped_line.end_with?(' BEGIN')

        # Detect end of block: "END" or "END;"
        in_block = false if ['END;', 'END'].include?(stripped_line)

        # Statement is complete when:
        # 1. Line ends with semicolon, AND
        # 2. We just closed a block (ended with END or END;), OR we're not in a block
        if line.strip.end_with?(';') && !in_block
          statements << current_statement.strip
          current_statement = +'' # Unfreeze new string
        end
      end

      # Add any remaining statement
      statements << current_statement.strip unless current_statement.strip.empty?

      # Execute each statement using raw connection
      statements.each_with_index do |statement, index|
        next if statement.empty?
        next if statement.start_with?('--') # Skip standalone comments

        begin
          # Use ActiveRecord connection execute which works for procedures/triggers
          connection.execute(statement)
        rescue StandardError => e
          # Log helpful error with statement number
          Rails.logger.error "Failed to execute MySQL statement #{index + 1}/#{statements.length}: #{e.message}"
          Rails.logger.error "Statement: #{statement[0..200]}"
          raise
        end
      end
    end
  end
end
