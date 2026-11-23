# frozen_string_literal: true

module BetterStructureSql
  # Handles loading schema from single file or multi-file directory
  class SchemaLoader
    class LoadError < StandardError; end

    # Line opening a compound statement block ("BEGIN", "FOR EACH ROW BEGIN", "label: BEGIN")
    MYSQL_BLOCK_START = /\bBEGIN\z/i

    # Line closing a block: "END", "END;" or "END label;" (not END IF, END LOOP, ...)
    MYSQL_BLOCK_END = /\AEND(?:\s+(?!(?:IF|LOOP|WHILE|CASE|REPEAT)\b)\w+)?\s*;?\z/i

    # Checksum Rails keeps as schema_sha1 to tell whether a database matches its schema
    #
    # @param path [String] Schema file or directory
    # @return [String] SHA1 of the file, or of every SQL file of the directory in path order
    def self.schema_sha1(path)
      files = File.directory?(path) ? Dir.glob(File.join(path, '**', '*.sql')) : [path]
      OpenSSL::Digest::SHA1.hexdigest(files.map { |file| File.read(file) }.join("\n"))
    end

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

    # Loads the schema, then records the environment and the schema checksum in
    # ar_internal_metadata, as Rails' own schema load does. Without the environment
    # Rails refuses to drop or purge the database later (NoEnvironmentInSchemaError).
    #
    # @param path [String, nil] Path to schema file or directory (defaults to config.output_path)
    # @return [void]
    def load_and_record(path = nil)
      path ||= config.output_path
      load(path)

      schema_sha1 = self.class.schema_sha1(Rails.root.join(path).to_s)
      internal_metadata.create_table_and_set_flags(ActiveRecord::Base.connection_db_config.env_name, schema_sha1)
    end

    private

    # Rails 7.2 moved internal_metadata from the connection to the pool
    def internal_metadata
      pool = ActiveRecord::Base.connection_pool
      pool.respond_to?(:internal_metadata) ? pool.internal_metadata : ActiveRecord::Base.connection.internal_metadata
    end

    def load_directory(dir_path)
      connection = ActiveRecord::Base.connection

      sql_files_in_load_order(dir_path).each do |file_path|
        sql_content = File.read(file_path)
        next if sql_content.strip.empty?

        execute_sql_statements(connection, sql_content)
      end

      Rails.logger.debug { "Schema loaded from #{dir_path}" }
    end

    # Header first, then the numbered directories (01_extensions through 20_migrations) in order
    def sql_files_in_load_order(dir_path)
      header_path = File.join(dir_path, '_header.sql')
      section_files = Dir.glob(File.join(dir_path, '[012]*_*')).flat_map do |dir|
        File.directory?(dir) ? Dir.glob(File.join(dir, '*.sql')) : []
      end

      (File.exist?(header_path) ? [header_path] : []) + section_files
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
        execute_sqlite_batch(connection, sql)
      when 'mysql', 'mysql2', 'trilogy'
        # MySQL needs statements executed individually
        execute_mysql_statements(connection, sql)
      else
        # PostgreSQL can handle multiple statements in one execute call
        connection.execute(sql)
      end
    end

    # ActiveRecord's SQLite execute runs only the first of several statements
    # (silently dropping the rest), so the batch goes to the raw connection;
    # its errors are re-raised as ActiveRecord::StatementInvalid like every
    # other adapter's.
    def execute_sqlite_batch(connection, sql)
      connection.raw_connection.execute_batch(sql)
    rescue SQLite3::Exception => e
      raise ActiveRecord::StatementInvalid.new(e.message, sql:)
    end

    # Execute a MySQL dump one statement at a time
    #
    # Statements are sent without their trailing ";" and with query transformers
    # (Rails query log tags) switched off: MySQL stores whatever follows the
    # body of a single-statement routine or trigger, so either would become
    # part of the object and grow on every dump/load cycle.
    def execute_mysql_statements(connection, sql)
      statements = split_mysql_statements(sql)

      without_query_transformers do
        statements.each_with_index do |statement, index|
          connection.execute(statement.delete_suffix(';'))
        rescue StandardError => e
          Rails.logger.error "Failed to execute MySQL statement #{index + 1}/#{statements.length}: #{e.message}"
          Rails.logger.error "Statement: #{statement[0..200]}"
          raise
        end
      end
    end

    # Split a MySQL dump into statements without needing DELIMITER
    #
    # A statement ends at a line ending in ";" outside any BEGIN ... END block.
    # Blocks nest (procedures with inner BEGIN ... END), so the depth is
    # counted; END IF/LOOP/WHILE/CASE/REPEAT close control flow, not blocks.
    #
    # @param sql [String] SQL text
    # @return [Array<String>] Statements, each ending in ";"
    def split_mysql_statements(sql)
      statements = []
      current = +''
      depth = 0

      sql.each_line do |line|
        stripped = line.strip
        next if current.empty? && (stripped.empty? || stripped.start_with?('--'))

        current << line
        depth += 1 if MYSQL_BLOCK_START.match?(stripped)
        depth -= 1 if MYSQL_BLOCK_END.match?(stripped)
        next unless depth.zero? && stripped.end_with?(';')

        statements << current.strip
        current = +''
      end

      statements << current.strip unless current.strip.empty?
      statements
    end

    def without_query_transformers
      transformers = ActiveRecord.query_transformers
      ActiveRecord.query_transformers = []
      yield
    ensure
      ActiveRecord.query_transformers = transformers
    end
  end
end
