# frozen_string_literal: true

module BetterStructureSql
  # Orchestrates database schema dumping to SQL files
  #
  # Coordinates introspection, SQL generation, formatting, and file output.
  # Supports both single-file and multi-file dump modes with optional
  # schema version storage.
  class Dumper
    attr_reader :config, :connection, :adapter

    def initialize(config = BetterStructureSql.configuration, connection = ActiveRecord::Base.connection)
      @config = config
      @connection = connection
      @adapter = Adapters::Registry.adapter_for(connection)
    end

    # Dumps database schema to configured output path
    #
    # @param store_version [Boolean, nil] Whether to store version (nil uses config default)
    # @return [String, Hash] Single file content or multi-file map
    # @raise [Error] If configuration is invalid
    def dump(store_version: nil)
      config.validate!

      output_mode = detect_output_mode

      if output_mode == :multi_file
        dump_multi_file(store_version: store_version)
      else
        dump_single_file(store_version: store_version)
      end
    end

    private

    # Detect if we're in single-file or multi-file mode
    def detect_output_mode
      FileWriter.new(config).detect_output_mode(config.output_path)
    end

    # Original single-file dump logic
    def dump_single_file(store_version: nil)
      output = []
      output << header
      output << extensions_section if config.include_extensions
      output << set_schema_section
      output << custom_types_section if config.include_custom_types
      output << domains_section if config.include_domains
      output << functions_section if config.include_functions
      output << sequences_section if config.include_sequences
      output << tables_section
      output << indexes_section
      output << foreign_keys_section
      output << views_section if config.include_views
      output << materialized_views_section if config.include_materialized_views
      output << triggers_section if config.include_triggers
      output << schema_migrations_section
      output << footer

      formatted_output = Formatter.new(config).format(output.compact.join("\n\n"))
      write_to_file(formatted_output)

      # Store version if requested and enabled
      store_version = config.enable_schema_versions if store_version.nil?
      store_schema_version(formatted_output) if store_version && config.enable_schema_versions

      formatted_output
    end

    # New multi-file dump logic
    def dump_multi_file(store_version: nil)
      # Generate sections as arrays of SQL strings instead of joined text
      sections = generate_sections_for_multi_file

      # Write files using FileWriter
      writer = FileWriter.new(config)
      header_content = [header, set_schema_section].compact.join("\n\n")
      file_map = writer.write_multi_file(config.output_path, sections, header_content)

      # Generate and write manifest
      if config.generate_manifest
        manifest_generator = ManifestGenerator.new(config)
        manifest_content = manifest_generator.generate(file_map)

        manifest_path = Rails.root.join(config.output_path, '_manifest.json')
        File.write(manifest_path, manifest_content)
      end

      # Store version if requested and enabled
      # For multi-file, combine all sections for storage
      store_version = config.enable_schema_versions if store_version.nil?
      if store_version && config.enable_schema_versions
        combined_content = combine_sections_for_storage(sections, header_content)
        store_schema_version(combined_content)
      end

      file_map
    end

    # Generate sections as structured data (arrays) instead of joined strings
    #
    # Refactored to extract section generation into dedicated methods for better readability
    def generate_sections_for_multi_file
      sections = {}

      sections[:extensions] = generate_extensions_section if config.include_extensions
      sections[:types] = generate_types_section if config.include_custom_types
      sections[:domains] = generate_domains_section if config.include_domains
      sections[:functions] = generate_functions_section if config.include_functions
      sections[:sequences] = generate_sequences_section if config.include_sequences
      sections[:tables] = generate_tables_section
      sections[:indexes] = generate_indexes_section
      sections[:foreign_keys] = generate_foreign_keys_section unless sqlite_adapter?
      sections[:views] = generate_views_section if config.include_views
      sections[:materialized_views] = generate_materialized_views_section if config.include_materialized_views
      sections[:triggers] = generate_triggers_section if config.include_triggers
      sections[:migrations] = generate_migrations_section unless sqlite_adapter?

      sections.compact
    end

    # Generate extensions section
    #
    # @return [Array<String>, nil] Array of CREATE EXTENSION statements or nil if empty
    def generate_extensions_section
      extensions = Introspection.fetch_extensions(connection)
      return nil if extensions.empty?

      generator = Generators::ExtensionGenerator.new(config)
      extensions.map { |ext| generator.generate(ext) }
    end

    # Generate custom types section (enums, composite types)
    #
    # @return [Array<String>, nil] Array of CREATE TYPE statements or nil if empty
    def generate_types_section
      types = Introspection.fetch_custom_types(connection).reject { |t| t[:type] == 'domain' }
      return nil if types.empty?

      generator = Generators::TypeGenerator.new(config)
      types.filter_map { |type| generator.generate(type) }
    end

    # Generate domains section
    #
    # @return [Array<String>, nil] Array of CREATE DOMAIN statements or nil if empty
    def generate_domains_section
      domains = Introspection.fetch_custom_types(connection).select { |t| t[:type] == 'domain' }
      return nil if domains.empty?

      generator = Generators::DomainGenerator.new(config)
      domains.map { |domain| generator.generate(domain) }
    end

    # Generate functions section
    #
    # @return [Array<String>, nil] Array of CREATE FUNCTION statements or nil if empty
    def generate_functions_section
      functions = Introspection.fetch_functions(connection)
      return nil if functions.empty?

      generator = Generators::FunctionGenerator.new(config)
      functions.map { |func| generator.generate(func) }
    end

    # Generate sequences section
    #
    # @return [Array<String>, nil] Array of CREATE SEQUENCE statements or nil if empty
    def generate_sequences_section
      sequences = Introspection.fetch_sequences(connection)
      return nil if sequences.empty?

      generator = Generators::SequenceGenerator.new(config)
      sequences.map { |seq| generator.generate(seq) }
    end

    # Generate tables section
    #
    # @return [Array<String>, nil] Array of CREATE TABLE statements or nil if empty
    def generate_tables_section
      tables = Introspection.fetch_tables(connection)
      tables = tables.sort_by { |t| t[:name] } if config.sort_tables
      return nil if tables.empty?

      attach_foreign_keys_for_sqlite(tables) if sqlite_adapter?

      generator = Generators::TableGenerator.new(config, adapter)
      tables.map { |table| generator.generate(table) }
    end

    # Generate indexes section
    #
    # @return [Array<String>, nil] Array of CREATE INDEX statements or nil if empty
    def generate_indexes_section
      indexes = Introspection.fetch_indexes(connection)
      return nil if indexes.empty?

      generator = Generators::IndexGenerator.new(config)
      indexes.map { |idx| generator.generate(idx) }
    end

    # Generate foreign keys section
    #
    # @return [Array<String>, nil] Array of ALTER TABLE ADD CONSTRAINT statements or nil if empty
    def generate_foreign_keys_section
      foreign_keys = Introspection.fetch_foreign_keys(connection)
      return nil if foreign_keys.empty?

      generator = Generators::ForeignKeyGenerator.new(config)
      foreign_keys.map { |fk| generator.generate(fk) }
    end

    # Generate views section
    #
    # @return [Array<String>, nil] Array of CREATE VIEW statements or nil if empty
    def generate_views_section
      views = Introspection.fetch_views(connection)
      return nil if views.empty?

      generator = Generators::ViewGenerator.new(config)
      views.map { |view| generator.generate(view) }
    end

    # Generate materialized views section
    #
    # @return [Array<String>, nil] Array of CREATE MATERIALIZED VIEW statements or nil if empty
    def generate_materialized_views_section
      matviews = Introspection.fetch_materialized_views(connection)
      return nil if matviews.empty?

      generator = Generators::MaterializedViewGenerator.new(config)
      matviews.map { |mv| generator.generate(mv) }
    end

    # Generate triggers section
    #
    # @return [Array<String>, nil] Array of CREATE TRIGGER statements or nil if empty
    def generate_triggers_section
      triggers = Introspection.fetch_triggers(connection)
      return nil if triggers.empty?

      generator = Generators::TriggerGenerator.new(config)
      triggers.map { |trigger| generator.generate(trigger) }
    end

    # Generate migrations section
    #
    # @return [Array<String>, nil] Array of batch INSERT statements or nil if empty
    def generate_migrations_section
      return nil unless table_exists?('schema_migrations')

      versions = fetch_schema_migration_versions
      return nil if versions.empty?

      chunk_size = config.max_lines_per_file - 3
      version_chunks = versions.each_slice(chunk_size).to_a

      version_chunks.map { |chunk| generate_migrations_batch(chunk) }
    end

    # Attach foreign keys to tables for SQLite inline generation
    #
    # @param tables [Array<Hash>] Array of table hashes
    # @return [void]
    def attach_foreign_keys_for_sqlite(tables)
      all_foreign_keys = Introspection.fetch_foreign_keys(connection)
      tables.each do |table|
        table[:foreign_keys] = all_foreign_keys.select { |fk| fk[:table] == table[:name] }
      end
    end

    # Check if current adapter is SQLite
    #
    # @return [Boolean] True if using SQLite adapter
    def sqlite_adapter?
      adapter.class.name == 'BetterStructureSql::Adapters::SqliteAdapter'
    end

    # Combine sections for database storage (when versioning is enabled)
    def combine_sections_for_storage(sections, header_content)
      output = [header_content]

      section_order = %i[
        extensions types domains functions sequences
        tables indexes foreign_keys views materialized_views triggers
      ]

      section_order.each do |section_key|
        next unless sections.key?(section_key)

        section_content = sections[section_key]
        next if section_content.blank?

        # Add section header
        header = "-- #{section_key.to_s.split('_').map(&:capitalize).join(' ')}"
        output << header
        output << section_content.join("\n\n")
      end

      # Add schema migrations
      migrations = schema_migrations_section
      output << migrations if migrations

      output << footer

      Formatter.new(config).format(output.compact.join("\n\n"))
    end

    def header
      case adapter.class.name
      when 'BetterStructureSql::Adapters::PostgresqlAdapter'
        <<~HEADER.strip
          SET client_encoding = 'UTF8';
          SET standard_conforming_strings = on;
        HEADER
      when 'BetterStructureSql::Adapters::SqliteAdapter'
        # SQLite PRAGMA statements for optimal behavior and compatibility
        <<~HEADER.strip
          PRAGMA foreign_keys = ON;
          PRAGMA defer_foreign_keys = ON;
        HEADER
      when 'BetterStructureSql::Adapters::MysqlAdapter'
        # MySQL doesn't need any header commands (or could set charset, etc.)
        nil
      else
        # Unknown adapter - no header
        nil
      end
    end

    def extensions_section
      extensions = Introspection.fetch_extensions(connection)
      return nil if extensions.empty?

      generator = Generators::ExtensionGenerator.new(config)
      # Use appropriate section name based on adapter
      section_name = adapter.class.name == 'BetterStructureSql::Adapters::SqliteAdapter' ? 'PRAGMAs' : 'Extensions'
      lines = ["-- #{section_name}"]
      lines += extensions.map { |ext| generator.generate(ext) }
      lines.join("\n")
    end

    def set_schema_section
      case adapter.class.name
      when 'BetterStructureSql::Adapters::PostgresqlAdapter'
        "SET search_path TO #{config.search_path};"
      when 'BetterStructureSql::Adapters::SqliteAdapter', 'BetterStructureSql::Adapters::MysqlAdapter'
        # SQLite and MySQL don't use search_path
        nil
      else
        nil
      end
    end

    def custom_types_section
      # Only include enums and composite types (not domains, they have their own section)
      types = Introspection.fetch_custom_types(connection).reject { |t| t[:type] == 'domain' }
      return nil if types.empty?

      generator = Generators::TypeGenerator.new(config)
      lines = types.filter_map { |type| generator.generate(type) }
      return nil if lines.empty?

      (['-- Custom Types'] + lines).join("\n")
    end

    def sequences_section
      sequences = Introspection.fetch_sequences(connection)
      return nil if sequences.empty?

      generator = Generators::SequenceGenerator.new(config)
      lines = ['-- Sequences']
      lines += sequences.map { |seq| generator.generate(seq) }
      lines.join("\n")
    end

    def tables_section
      tables = Introspection.fetch_tables(connection)
      tables = tables.sort_by { |t| t[:name] } if config.sort_tables

      return '-- Tables' if tables.empty?

      # For SQLite, attach foreign keys to each table for inline generation
      if adapter.class.name == 'BetterStructureSql::Adapters::SqliteAdapter'
        all_foreign_keys = Introspection.fetch_foreign_keys(connection)
        tables.each do |table|
          table[:foreign_keys] = all_foreign_keys.select { |fk| fk[:table] == table[:name] }
        end
      end

      generator = Generators::TableGenerator.new(config, adapter)
      lines = []

      # Add PostgreSQL-specific SET commands only for PostgreSQL
      if adapter.class.name == 'BetterStructureSql::Adapters::PostgresqlAdapter'
        lines << "SET default_tablespace = '';"
        lines << ''
        lines << 'SET default_table_access_method = heap;'
        lines << ''
      end

      lines << '-- Tables'
      lines += tables.map { |table| generator.generate(table) }
      lines.join("\n\n")
    end

    def indexes_section
      indexes = Introspection.fetch_indexes(connection)
      return nil if indexes.empty?

      generator = Generators::IndexGenerator.new(config)
      lines = ['-- Indexes']
      lines += indexes.map { |idx| generator.generate(idx) }
      lines.join("\n")
    end

    def foreign_keys_section
      # SQLite foreign keys are inline with CREATE TABLE, not separate ALTER TABLE statements
      return nil if adapter.class.name == 'BetterStructureSql::Adapters::SqliteAdapter'

      foreign_keys = Introspection.fetch_foreign_keys(connection)
      return nil if foreign_keys.empty?

      generator = Generators::ForeignKeyGenerator.new(config)
      lines = ['-- Foreign Keys']
      lines += foreign_keys.map { |fk| generator.generate(fk) }
      lines.join("\n")
    end

    def domains_section
      domains = Introspection.fetch_custom_types(connection).select { |t| t[:type] == 'domain' }
      return nil if domains.empty?

      generator = Generators::DomainGenerator.new(config)
      lines = ['-- Domains']
      lines += domains.map { |domain| generator.generate(domain) }
      lines.join("\n")
    end

    def functions_section
      functions = Introspection.fetch_functions(connection)
      return nil if functions.empty?

      generator = Generators::FunctionGenerator.new(config)
      lines = ['-- Functions']
      lines += functions.map { |func| generator.generate(func) }
      lines.join("\n\n")
    end

    def views_section
      views = Introspection.fetch_views(connection)
      return nil if views.empty?

      generator = Generators::ViewGenerator.new(config)
      lines = ['-- Views']
      lines += views.map { |view| generator.generate(view) }
      lines.join("\n\n")
    end

    def materialized_views_section
      matviews = Introspection.fetch_materialized_views(connection)
      return nil if matviews.empty?

      generator = Generators::MaterializedViewGenerator.new(config)
      lines = ['-- Materialized Views']
      lines += matviews.map { |mv| generator.generate(mv) }
      lines.join("\n\n")
    end

    def triggers_section
      triggers = Introspection.fetch_triggers(connection)
      return nil if triggers.empty?

      generator = Generators::TriggerGenerator.new(config)
      lines = ['-- Triggers']
      lines += triggers.map { |trigger| generator.generate(trigger) }
      lines.join("\n\n")
    end

    def schema_migrations_section
      # SQLite doesn't include schema_migrations in structure.sql
      # Rails manages this table separately
      return nil if adapter.class.name == 'BetterStructureSql::Adapters::SqliteAdapter'

      return nil unless table_exists?('schema_migrations')

      versions = fetch_schema_migration_versions
      return nil if versions.empty?

      # Use adapter-specific quoting
      table_quote = quote_table_name('schema_migrations')

      lines = ['-- Schema Migrations']

      # Use adapter-specific conflict resolution and quoting
      case adapter.class.name
      when 'BetterStructureSql::Adapters::PostgresqlAdapter'
        lines << "INSERT INTO #{table_quote} (version) VALUES"
        lines << versions.map { |v| "('#{v}')" }.join(",\n")
        lines << 'ON CONFLICT DO NOTHING;'
      when 'BetterStructureSql::Adapters::MysqlAdapter'
        # MySQL uses INSERT IGNORE and backticks
        lines << "INSERT IGNORE INTO #{table_quote} (version) VALUES"
        lines << versions.map { |v| "('#{v}')" }.join(",\n")
        lines << ';'
      else
        lines << "INSERT INTO #{table_quote} (version) VALUES"
        lines << versions.map { |v| "('#{v}')" }.join(",\n")
        lines << ';'
      end

      lines.join("\n")
    end

    def search_path_section
      "SET search_path TO #{config.search_path};"
    end

    def footer
      '' # Just a blank line to ensure newline at end
    end

    def write_to_file(content)
      file_path = Rails.root.join(config.output_path)
      FileUtils.mkdir_p(File.dirname(file_path))
      File.write(file_path, content)
    end

    def table_exists?(table_name)
      connection.table_exists?(table_name)
    end

    def fetch_schema_migration_versions
      connection.select_values('SELECT version FROM schema_migrations ORDER BY version')
    rescue ActiveRecord::StatementInvalid
      []
    end

    def generate_migrations_batch(versions)
      return '' if versions.empty?

      # Use adapter-specific quoting
      table_quote = quote_table_name('schema_migrations')

      # Generate single batch INSERT with all versions
      # This will be chunked by FileWriter if it exceeds max_lines_per_file
      lines = []

      # Use adapter-specific conflict resolution and quoting
      case adapter.class.name
      when 'BetterStructureSql::Adapters::PostgresqlAdapter'
        lines << "INSERT INTO #{table_quote} (version) VALUES"
        lines << versions.map { |v| "('#{v}')" }.join(",\n")
        lines << 'ON CONFLICT DO NOTHING;'
      when 'BetterStructureSql::Adapters::MysqlAdapter'
        # MySQL uses INSERT IGNORE and backticks
        lines << "INSERT IGNORE INTO #{table_quote} (version) VALUES"
        lines << versions.map { |v| "('#{v}')" }.join(",\n")
        lines << ';'
      else
        lines << "INSERT INTO #{table_quote} (version) VALUES"
        lines << versions.map { |v| "('#{v}')" }.join(",\n")
        lines << ';'
      end

      lines.join("\n")
    end

    def quote_table_name(table_name)
      case adapter.class.name
      when 'BetterStructureSql::Adapters::MysqlAdapter'
        "`#{table_name}`"
      else
        "\"#{table_name}\""
      end
    end

    def store_schema_version(content)
      pg_version = PgVersion.detect(connection)

      SchemaVersions.store(
        content: content,
        format_type: 'sql',
        pg_version: pg_version,
        connection: connection
      )
    rescue StandardError => e
      # Log error but don't fail the dump
      warn "Warning: Failed to store schema version: #{e.message}"
    end
  end
end
