# frozen_string_literal: true

module BetterStructureSql
  # Orchestrates database schema dumping to SQL files
  #
  # Coordinates introspection, SQL generation, formatting, and file output.
  # Supports both single-file and multi-file dump modes with optional
  # schema version storage.
  class Dumper
    # Lines an INSERT statement adds around its list of versions
    MIGRATION_INSERT_OVERHEAD_LINES = 3

    # Titles of the runs a dependency-ordered sequence is split into in the single-file dump
    SECTION_TITLES = {
      types: '-- Custom Types',
      domains: '-- Domains',
      functions: '-- Functions',
      views: '-- Views',
      materialized_views: '-- Materialized Views'
    }.freeze

    # Sections whose statements are separated by a newline instead of a blank line
    COMPACT_SECTIONS = %i[types domains].freeze

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
      @creation_order = @functions = @custom_types = nil

      output_mode = detect_output_mode

      if output_mode == :multi_file
        dump_multi_file(store_version:)
      else
        dump_single_file(store_version:)
      end
    end

    private

    # Whether this dump should also store a schema version (nil defers to configuration)
    def store_version?(requested)
      requested = config.enable_schema_versions if requested.nil?
      requested && config.enable_schema_versions
    end

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
      output.concat(titled_runs(type_statements))
      output.concat(titled_runs(early_statements))
      output << sequences_section if config.include_sequences
      output << tables_section
      output << indexes_section
      output << foreign_keys_section
      output.concat(titled_runs(relation_dependent_statements))
      output << triggers_section if config.include_triggers
      output << comments_section if config.include_comments
      output << schema_migrations_section
      output << footer

      formatted_output = Formatter.new(config).format(output.compact.join("\n\n"))
      FileWriter.new(config).write_single_file(config.output_path, formatted_output)
      store_schema_version if store_version?(store_version)

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

      manifest_content = ManifestGenerator.new(config).generate(file_map) if config.generate_manifest
      writer.write_manifest(config.output_path, manifest_content)
      store_schema_version if store_version?(store_version)

      file_map
    end

    # Generate sections as structured data (arrays) instead of joined strings
    #
    # Refactored to extract section generation into dedicated methods for better readability
    def generate_sections_for_multi_file
      sections = {}

      sections[:extensions] = generate_extensions_section if config.include_extensions
      sections[:types] = type_statements.map(&:last).presence
      sections[:functions] = early_statements.map(&:last).presence
      sections[:sequences] = generate_sequences_section if config.include_sequences
      sections[:tables] = generate_tables_section
      sections[:indexes] = generate_indexes_section
      sections[:foreign_keys] = generate_foreign_keys_section unless sqlite_adapter?
      sections[:views] = relation_dependent_statements.map(&:last).presence
      sections[:triggers] = generate_triggers_section if config.include_triggers
      sections[:comments] = generate_comments_section if config.include_comments
      sections[:migrations] = generate_migrations_section

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
      tables = ordered_tables
      return nil if tables.empty?

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

    # Generate triggers section
    #
    # @return [Array<String>, nil] Array of CREATE TRIGGER statements or nil if empty
    def generate_triggers_section
      triggers = Introspection.fetch_triggers(connection)
      return nil if triggers.empty?

      generator = Generators::TriggerGenerator.new(config)
      triggers.map { |trigger| generator.generate(trigger) }
    end

    # Generate comments section
    #
    # @return [Array<String>, nil] Array of COMMENT ON statements or nil if empty
    def generate_comments_section
      return nil unless adapter.supports_comments?

      all_comments = adapter.fetch_comments(connection)
      generator = Generators::CommentGenerator.new(config)

      comments = all_comments[:tables].map do |table_name, comment|
        generator.generate(object_type: :table, object_name: table_name, comment:)
      end
      all_comments[:columns].each do |(table_name, column_name), comment|
        comments << generator.generate(object_type: :column, table_name:, object_name: column_name, comment:)
      end
      { index: :indexes, view: :views, function: :functions, procedure: :procedures }.each do |object_type, key|
        all_comments.fetch(key).each do |object_name, comment|
          comments << generator.generate(object_type:, object_name:, comment:)
        end
      end

      comments.presence
    end

    # Generate migrations section
    #
    # @return [Array<String>, nil] Array of batch INSERT statements or nil if empty
    def generate_migrations_section
      return nil unless table_exists?('schema_migrations')

      versions = fetch_schema_migration_versions
      return nil if versions.empty?

      versions.each_slice(migrations_per_insert).map { |chunk| generate_migrations_batch(chunk) }
    end

    # Versions per INSERT statement, leaving room for the INSERT and conflict lines in a file
    #
    # @return [Integer] Number of versions (at least one)
    def migrations_per_insert
      [config.max_lines_per_file - MIGRATION_INSERT_OVERHEAD_LINES, 1].max
    end

    # Check if current adapter is SQLite
    #
    # @return [Boolean] True if using SQLite adapter
    def sqlite_adapter?
      adapter.class.name == 'BetterStructureSql::Adapters::SqliteAdapter'
    end

    def header
      case adapter.class.name
      when 'BetterStructureSql::Adapters::PostgresqlAdapter'
        <<~HEADER.strip
          SET client_encoding = 'UTF8';
          SET standard_conforming_strings = on;
          SET check_function_bodies = false;
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

    def sequences_section
      sequences = Introspection.fetch_sequences(connection)
      return nil if sequences.empty?

      generator = Generators::SequenceGenerator.new(config)
      lines = ['-- Sequences']
      lines += sequences.map { |seq| generator.generate(seq) }
      lines.join("\n")
    end

    # Tables in dump order: by name when sort_tables is set, except that an
    # inheritance child is deferred until right after the last of its parents
    def ordered_tables
      tables = Introspection.fetch_tables(connection)
      tables = tables.sort_by { |t| t[:name] } if config.sort_tables
      names = tables.to_set { |table| table[:name] }

      placed = Set.new
      waiting = []
      ordered = []
      place = lambda do |table|
        ordered << table
        placed << table[:name]
        ready, waiting = waiting.partition { |child| parents_placed?(child, names, placed) }
        ready.each(&place)
      end
      tables.each { |table| parents_placed?(table, names, placed) ? place.call(table) : waiting << table }
      ordered + waiting
    end

    def parents_placed?(table, names, placed)
      Array(table[:inherits]).all? { |parent| placed.include?(parent) || names.exclude?(parent) }
    end

    def tables_section
      tables = ordered_tables

      return '-- Tables' if tables.empty?

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

    # Dependency information for this dump (queried once)
    def creation_order
      @creation_order ||= CreationOrder.for(adapter, connection)
    end

    def functions
      @functions ||= config.include_functions ? Introspection.fetch_functions(connection) : []
    end

    def keyed_functions
      functions.map { |function| [CreationOrder.function_key(function), function] }
    end

    # Enums, composites, ranges and domains the dump includes, in name order within each kind
    def custom_types
      @custom_types ||= begin
        types = Introspection.fetch_custom_types(connection)
        domains, others = types.partition { |type| type[:type] == 'domain' }
        (config.include_custom_types ? others : []) + (config.include_domains ? domains : [])
      end
    end

    def keyed_type_statements
      generator = Generators::TypeGenerator.new(config)
      custom_types.filter_map do |type|
        statement = generator.generate(type)
        statement && [CreationOrder.type_key(type[:name]), [type[:type] == 'domain' ? :domains : :types, statement]]
      end
    end

    # Custom types that need no routine, dependency-ordered: created first
    #
    # @return [Array<Array(Symbol, String)>] Pairs of section and SQL statement
    def type_statements
      creation_order.sort(keyed_type_statements.reject { |key, _statement| creation_order.needs_function?(key) })
    end

    # Functions that need no relation, together with the custom types that need a
    # routine (a domain CHECK calling a function, a range's canonical function),
    # dependency-ordered: created before tables, whose defaults, checks and indexes may use them
    #
    # @return [Array<Array(Symbol, String)>] Pairs of section and SQL statement
    def early_statements
      generator = Generators::FunctionGenerator.new(config)
      function_statements = keyed_functions.reject { |key, _function| creation_order.needs_relation?(key) }.map do |key, function|
        [key, [:functions, generator.generate(function)]]
      end
      type_statements = keyed_type_statements.select { |key, _statement| creation_order.needs_function?(key) }

      creation_order.sort(type_statements + function_statements)
    end

    # Views, materialized views and the functions that need a relation, as one
    # sequence in which every object follows the objects it depends on
    #
    # @return [Array<Array(Symbol, String)>] Pairs of section and SQL statement
    def relation_dependent_statements
      creation_order.sort(view_statements + materialized_view_statements + relation_dependent_function_statements)
    end

    def view_statements
      return [] unless config.include_views

      generator = Generators::ViewGenerator.new(config)
      Introspection.fetch_views(connection).map do |view|
        [CreationOrder.relation_key(view[:name]), [:views, generator.generate(view)]]
      end
    end

    def materialized_view_statements
      return [] unless config.include_materialized_views

      generator = Generators::MaterializedViewGenerator.new(config)
      Introspection.fetch_materialized_views(connection).map do |matview|
        [CreationOrder.relation_key(matview[:name]), [:materialized_views, generator.generate(matview)]]
      end
    end

    def relation_dependent_function_statements
      generator = Generators::FunctionGenerator.new(config)
      keyed_functions.select { |key, _function| creation_order.needs_relation?(key) }.map do |key, function|
        [key, [:functions, generator.generate(function)]]
      end
    end

    # Groups dependency-ordered statements into titled runs for the single-file dump
    #
    # @param statements [Array<Array(Symbol, String)>] Pairs of section and SQL statement
    # @return [Array<String>] One text block per run of statements of the same section
    def titled_runs(statements)
      statements.chunk_while { |(left, _), (right, _)| left == right }.map do |run|
        section = run.first.first
        separator = COMPACT_SECTIONS.include?(section) ? "\n" : "\n\n"
        ([SECTION_TITLES.fetch(section)] + run.map(&:last)).join(separator)
      end
    end

    def triggers_section
      triggers = Introspection.fetch_triggers(connection)
      return nil if triggers.empty?

      generator = Generators::TriggerGenerator.new(config)
      lines = ['-- Triggers']
      lines += triggers.map { |trigger| generator.generate(trigger) }
      lines.join("\n\n")
    end

    def comments_section
      statements = generate_comments_section
      statements && (['-- Comments'] + statements).join("\n")
    end

    def schema_migrations_section
      return nil unless table_exists?('schema_migrations')

      versions = fetch_schema_migration_versions
      return nil if versions.empty?

      "-- Schema Migrations\n#{generate_migrations_batch(versions)}"
    end

    def footer
      '' # Just a blank line to ensure newline at end
    end

    def table_exists?(table_name)
      connection.table_exists?(table_name)
    end

    def fetch_schema_migration_versions
      connection.select_values('SELECT version FROM schema_migrations ORDER BY version')
    end

    def generate_migrations_batch(versions)
      values = versions.map { |version| "(#{connection.quote(version)})" }.join(",\n")

      [migrations_insert_prefix, values, migrations_insert_suffix].join("\n")
    end

    def migrations_insert_prefix
      keyword = adapter.class.name == 'BetterStructureSql::Adapters::MysqlAdapter' ? 'INSERT IGNORE' : 'INSERT'
      "#{keyword} INTO #{quote_table_name('schema_migrations')} (version) VALUES"
    end

    def migrations_insert_suffix
      adapter.class.name == 'BetterStructureSql::Adapters::PostgresqlAdapter' ? 'ON CONFLICT DO NOTHING;' : ';'
    end

    def quote_table_name(table_name)
      case adapter.class.name
      when 'BetterStructureSql::Adapters::MysqlAdapter'
        "`#{table_name}`"
      else
        "\"#{table_name}\""
      end
    end

    # Stores the schema that was just written; failures propagate so they are never mistaken for success
    def store_schema_version
      SchemaVersions.store_current(connection, config:)
    end
  end
end
