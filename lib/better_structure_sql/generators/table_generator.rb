# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Generates CREATE TABLE statements with columns and constraints
    #
    # Handles column definitions (identity, generated, collation), primary keys,
    # constraints and PostgreSQL partitioning; SQLite tables are replayed verbatim.
    # Statements that need the table to exist (NOT VALID constraints, sequence
    # ownership, partitions) follow the CREATE TABLE statement.
    class TableGenerator < Base
      attr_reader :adapter

      def initialize(config, adapter = nil)
        super(config)
        @adapter = adapter
      end

      # Generates CREATE TABLE statement
      #
      # @param table [Hash] Table metadata with columns and constraints
      # @return [String] SQL statement(s)
      def generate(table)
        statements = [create_table_statement(table)]
        statements.concat(not_valid_constraint_statements(table))
        statements.concat(owned_sequence_statements(table))
        statements.concat(Array(table[:partitions]).map { |partition| generate(partition) })
        statements.join("\n\n")
      end

      private

      # Build the CREATE TABLE statement itself
      #
      # SQLite tables are emitted as stored in sqlite_master (:sql): only that
      # statement carries AUTOINCREMENT, WITHOUT ROWID, STRICT, collations,
      # unnamed CHECKs and inline foreign keys, and replaying it keeps
      # sqlite_master identical after a load.
      #
      # @param table [Hash] Table metadata
      # @return [String] CREATE TABLE statement
      def create_table_statement(table)
        return create_partition_statement(table) if table[:partition_of]
        return "#{table.fetch(:sql)};" if sqlite_adapter?

        lines = ["#{create_table_prefix(table)} ("]
        lines << build_table_contents(table)
        lines << ")#{inherits_clause(table)}#{partition_by_clause(table)}#{storage_parameters_clause(table)}#{table_options(table)};"
        lines.join("\n")
      end

      # @param table [Hash] Table metadata with optional :unlogged
      # @return [String] CREATE [UNLOGGED] TABLE IF NOT EXISTS <name>
      def create_table_prefix(table)
        "CREATE #{'UNLOGGED ' if table[:unlogged]}TABLE IF NOT EXISTS #{quote_identifier(table[:name])}"
      end

      # Build INHERITS clause for a PostgreSQL inheritance child
      #
      # @param table [Hash] Table metadata with optional :inherits (parent names)
      # @return [String] INHERITS clause or empty string
      def inherits_clause(table)
        parents = Array(table[:inherits])
        parents.any? ? " INHERITS (#{parents.map { |parent| quote_identifier(parent) }.join(', ')})" : ''
      end

      # Build WITH (...) clause for PostgreSQL storage parameters
      #
      # @param table [Hash] Table metadata with optional :storage_parameters (e.g. "fillfactor=70")
      # @return [String] WITH clause or empty string
      def storage_parameters_clause(table)
        table[:storage_parameters] ? " WITH (#{table[:storage_parameters]})" : ''
      end

      # Build MySQL table options (storage engine and default collation)
      #
      # Without them the loaded table takes the server/database defaults, which
      # changes every column whose collation was the table default.
      #
      # @param table [Hash] Table metadata with optional :engine and :collation
      # @return [String] Table options or empty string
      def table_options(table)
        return '' unless table[:engine]

        " ENGINE=#{table[:engine]} DEFAULT COLLATE=#{table[:collation]}"
      end

      # Build CREATE TABLE ... PARTITION OF for a partition
      #
      # Columns come from the parent; only the partition's own constraints are listed.
      #
      # @param table [Hash] Partition metadata
      # @return [String] CREATE TABLE statement
      def create_partition_statement(table)
        constraints = build_constraints_clauses(table)
        constraints_list = constraints.any? ? " (\n#{constraints.map { |line| indent(line) }.join(",\n")}\n)" : ''

        "#{create_table_prefix(table)} " \
          "PARTITION OF #{quote_identifier(table[:partition_of])}#{constraints_list} " \
          "#{table[:partition_bound]}#{partition_by_clause(table)}#{storage_parameters_clause(table)};"
      end

      # Build PARTITION BY clause for partitioned tables
      #
      # @param table [Hash] Table metadata
      # @return [String] PARTITION BY clause or empty string
      def partition_by_clause(table)
        table[:partition_key] ? " PARTITION BY #{table[:partition_key]}" : ''
      end

      # Build table contents (columns, primary key, constraints)
      #
      # @param table [Hash] Table metadata
      # @return [String] Formatted table contents
      def build_table_contents(table)
        column_defs = build_column_definitions(table)
        column_defs << build_primary_key_clause(table) if table[:primary_key]&.any?
        column_defs.concat(build_constraints_clauses(table))

        column_defs.map { |def_line| indent(def_line) }.join(",\n")
      end

      # Build column definitions
      #
      # @param table [Hash] Table metadata
      # @return [Array<String>] Array of column definition strings
      def build_column_definitions(table)
        table[:columns].map { |col| column_definition(col, table) }
      end

      # Build primary key clause
      #
      # The constraint name is only spelled out when it differs from PostgreSQL's
      # default "<table>_pkey".
      #
      # @param table [Hash] Table metadata
      # @return [String] PRIMARY KEY clause
      def build_primary_key_clause(table)
        pk_cols = table[:primary_key].map { |col| quote_identifier(col) }.join(', ')
        clause = "PRIMARY KEY (#{pk_cols})"
        name = table[:primary_key_name]
        return clause if name.nil? || name == "#{table[:name]}_pkey"

        "CONSTRAINT #{quote_identifier(name)} #{clause}"
      end

      # Build constraints clauses (NOT VALID constraints are added after the table)
      #
      # @param table [Hash] Table metadata
      # @return [Array<String>] Array of constraint definition strings
      def build_constraints_clauses(table)
        Array(table[:constraints]).reject { |constraint| not_valid?(constraint) }
                                  .map { |constraint| constraint_definition(constraint) }
      end

      # Build ALTER TABLE statements for NOT VALID constraints
      #
      # PostgreSQL ignores NOT VALID inside CREATE TABLE, so these must be added afterwards.
      #
      # @param table [Hash] Table metadata
      # @return [Array<String>] ALTER TABLE statements
      def not_valid_constraint_statements(table)
        Array(table[:constraints]).select { |constraint| not_valid?(constraint) }.map do |constraint|
          "ALTER TABLE #{quote_identifier(table[:name])} ADD #{constraint_definition(constraint)};"
        end
      end

      # Build ALTER SEQUENCE ... OWNED BY statements for serial columns
      #
      # @param table [Hash] Table metadata
      # @return [Array<String>] ALTER SEQUENCE statements
      def owned_sequence_statements(table)
        Array(table[:owned_sequences]).map do |owned|
          "ALTER SEQUENCE #{quote_identifier(owned[:sequence])} " \
            "OWNED BY #{quote_identifier(table[:name])}.#{quote_identifier(owned[:column])};"
        end
      end

      def not_valid?(constraint)
        constraint[:validated] == false
      end

      # Build one column definition
      #
      # The collation is omitted when it is the table's default collation.
      #
      # @param column [Hash] Column metadata
      # @param table [Hash] Table metadata (for its default :collation)
      # @return [String] Column definition
      def column_definition(column, table)
        parts = [quote_identifier(column[:name]), column[:type]]

        parts << "COLLATE #{column[:collation]}" if column[:collation] && column[:collation] != table[:collation]
        parts << generated_clause(column[:generated]) if column[:generated]
        parts << 'NOT NULL' unless column[:nullable]

        if column[:default]
          default_value = format_default(column[:default])
          parts << "DEFAULT #{default_value}"
        end

        parts << 'AUTO_INCREMENT' if column[:auto_increment]
        parts << "ON UPDATE #{column[:on_update]}" if column[:on_update]
        parts << identity_clause(column[:identity]) if column[:identity]

        parts.join(' ')
      end

      # Build GENERATED ALWAYS AS (...) clause for generated columns
      #
      # @param generated [Hash] Generated column metadata with :expression and :kind
      # @return [String] Generated column clause
      def generated_clause(generated)
        "GENERATED ALWAYS AS (#{generated[:expression]}) #{generated[:kind]}"
      end

      # Build GENERATED ... AS IDENTITY clause with sequence options
      #
      # @param identity [Hash] Identity metadata with :generation and sequence options
      # @return [String] Identity clause
      def identity_clause(identity)
        options = SequenceGenerator.new(config).options(identity)
        "GENERATED #{identity[:generation]} AS IDENTITY (#{options.join(' ')})"
      end

      def constraint_definition(constraint)
        "CONSTRAINT #{quote_identifier(constraint[:name])} #{constraint[:definition]}"
      end

      def format_default(default_value)
        return default_value if default_value.nil?

        # PostgreSQL (pg_get_expr) and MySQL adapters report defaults as SQL, never as raw values
        return default_value if postgresql_adapter? || mysql_adapter_instance?

        # Handle nextval for sequences
        return default_value if default_value.start_with?('nextval(')

        # Handle NULL
        return 'NULL' if default_value.upcase == 'NULL'

        # Handle boolean values
        return default_value if %w[true false].include?(default_value.downcase)

        # Handle numeric values
        return default_value if default_value.match?(/\A-?\d+(\.\d+)?\z/)

        # Handle functions and expressions
        return default_value if default_value.include?('(') || default_value.upcase.start_with?('CURRENT_')

        # Otherwise, assume it's a string and quote it if not already quoted
        default_value.start_with?("'") ? default_value : "'#{default_value}'"
      end

      def sqlite_adapter?
        adapter&.class&.name == 'BetterStructureSql::Adapters::SqliteAdapter'
      end

      def mysql_adapter_instance?
        adapter&.class&.name == 'BetterStructureSql::Adapters::MysqlAdapter'
      end

      def postgresql_adapter?
        adapter&.class&.name == 'BetterStructureSql::Adapters::PostgresqlAdapter'
      end
    end
  end
end
