module BetterStructureSql
  class Dumper
    attr_reader :config, :connection

    def initialize(config = BetterStructureSql.configuration, connection = ActiveRecord::Base.connection)
      @config = config
      @connection = connection
    end

    def dump(store_version: nil)
      config.validate!

      output = []
      output << header
      output << extensions_section if config.include_extensions
      output << custom_types_section if config.include_custom_types
      output << sequences_section if config.include_sequences
      output << tables_section
      output << indexes_section
      output << foreign_keys_section
      output << schema_migrations_section
      output << search_path_section
      output << footer

      formatted_output = Formatter.new(config).format(output.compact.join("\n\n"))
      write_to_file(formatted_output)

      # Store version if requested and enabled
      store_version = config.enable_schema_versions if store_version.nil?
      if store_version && config.enable_schema_versions
        store_schema_version(formatted_output)
      end

      formatted_output
    end

    private

    def header
      "SET client_encoding = 'UTF8';"
    end

    def extensions_section
      extensions = Introspection.fetch_extensions(connection)
      return nil if extensions.empty?

      generator = Generators::ExtensionGenerator.new(config)
      lines = ["-- Extensions"]
      lines += extensions.map { |ext| generator.generate(ext) }
      lines.join("\n")
    end

    def custom_types_section
      types = Introspection.fetch_custom_types(connection)
      return nil if types.empty?

      generator = Generators::TypeGenerator.new(config)
      lines = ["-- Custom Types"]
      lines += types.map { |type| generator.generate(type) }.compact
      lines.join("\n")
    end

    def sequences_section
      sequences = Introspection.fetch_sequences(connection)
      return nil if sequences.empty?

      generator = Generators::SequenceGenerator.new(config)
      lines = ["-- Sequences"]
      lines += sequences.map { |seq| generator.generate(seq) }
      lines.join("\n")
    end

    def tables_section
      tables = Introspection.fetch_tables(connection)
      tables = tables.sort_by { |t| t[:name] } if config.sort_tables

      return "-- Tables" if tables.empty?

      generator = Generators::TableGenerator.new(config)
      lines = ["-- Tables"]
      lines += tables.map { |table| generator.generate(table) }
      lines.join("\n\n")
    end

    def indexes_section
      indexes = Introspection.fetch_indexes(connection)
      return nil if indexes.empty?

      generator = Generators::IndexGenerator.new(config)
      lines = ["-- Indexes"]
      lines += indexes.map { |idx| generator.generate(idx) }
      lines.join("\n")
    end

    def foreign_keys_section
      foreign_keys = Introspection.fetch_foreign_keys(connection)
      return nil if foreign_keys.empty?

      generator = Generators::ForeignKeyGenerator.new(config)
      lines = ["-- Foreign Keys"]
      lines += foreign_keys.map { |fk| generator.generate(fk) }
      lines.join("\n")
    end

    def schema_migrations_section
      return nil unless table_exists?("schema_migrations")

      versions = fetch_schema_migration_versions
      return nil if versions.empty?

      lines = ["-- Schema Migrations"]
      lines << "INSERT INTO \"schema_migrations\" (version) VALUES"
      lines << versions.map { |v| "('#{v}')" }.join(",\n")
      lines << "ON CONFLICT DO NOTHING;"
      lines.join("\n")
    end

    def search_path_section
      "SET search_path TO #{config.search_path};"
    end

    def footer
      <<~FOOTER.strip
        --
        -- PostgreSQL database dump complete
        --
      FOOTER
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
      connection.select_values("SELECT version FROM schema_migrations ORDER BY version")
    rescue ActiveRecord::StatementInvalid
      []
    end

    def store_schema_version(content)
      pg_version = PgVersion.detect(connection)

      SchemaVersions.store(
        content: content,
        format_type: "sql",
        pg_version: pg_version,
        connection: connection
      )
    rescue => e
      # Log error but don't fail the dump
      warn "Warning: Failed to store schema version: #{e.message}"
    end
  end
end
