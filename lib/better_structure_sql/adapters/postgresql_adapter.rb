# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # PostgreSQL adapter implementing all introspection and generation methods
    #
    # Provides full PostgreSQL support including extensions, custom types, materialized views,
    # functions, triggers, sequences, and all standard database objects.
    # Preserves existing query logic for backward compatibility.
    class PostgresqlAdapter < BaseAdapter
      # Introspection methods - migrated from Introspection modules

      # Fetch all extensions from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of extension hashes with :name, :version, :schema
      def fetch_extensions(connection)
        query = <<~SQL.squish
          SELECT extname, extversion, nspname as schema_name
          FROM pg_extension
          JOIN pg_namespace ON pg_namespace.oid = pg_extension.extnamespace
          WHERE nspname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY extname
        SQL

        connection.execute(query).map do |row|
          {
            name: row['extname'],
            version: row['extversion'],
            schema: row['schema_name']
          }
        end
      end

      # Fetch all custom types (enums, composite types, domains) from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of type hashes with :name, :schema, :type, and type-specific attributes
      def fetch_custom_types(connection)
        query = custom_types_query
        connection.execute(query).map { |row| build_custom_type(connection, row) }
      end

      # Fetch all tables from the database
      #
      # Performance optimized: Batches all table metadata queries to avoid N+1 queries.
      # For 1000 tables: 4 queries instead of 3001 queries (~750x faster)
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of table hashes with :name, :schema, :columns, :primary_key, :constraints
      def fetch_tables(connection)
        # Fetch all table names first
        tables_query = <<~SQL.squish
          SELECT table_name, table_schema
          FROM information_schema.tables
          WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
            AND table_type = 'BASE TABLE'
          ORDER BY table_name
        SQL

        table_rows = connection.execute(tables_query).to_a
        return [] if table_rows.empty?

        table_names = table_rows.pluck('table_name')

        # Batch fetch all columns, primary keys, and constraints
        columns_by_table = fetch_all_columns(connection, table_names)
        primary_keys_by_table = fetch_all_primary_keys(connection, table_names)
        constraints_by_table = fetch_all_constraints(connection, table_names)

        # Combine results
        table_rows.map do |row|
          table_name = row['table_name']
          {
            name: table_name,
            schema: row['table_schema'],
            columns: columns_by_table[table_name] || [],
            primary_key: primary_keys_by_table[table_name] || [],
            constraints: constraints_by_table[table_name] || []
          }
        end
      end

      # Fetch all indexes from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of index hashes with :schema, :table, :name, :definition
      def fetch_indexes(connection)
        query = <<~SQL.squish
          SELECT
            pi.schemaname,
            pi.tablename,
            pi.indexname,
            pi.indexdef
          FROM pg_indexes pi
          LEFT JOIN pg_matviews mv ON mv.matviewname = pi.tablename AND mv.schemaname = pi.schemaname
          WHERE pi.schemaname NOT IN ('pg_catalog', 'information_schema')
            AND mv.matviewname IS NULL
          ORDER BY pi.tablename, pi.indexname
        SQL

        connection.execute(query).map do |row|
          {
            schema: row['schemaname'],
            table: row['tablename'],
            name: row['indexname'],
            definition: row['indexdef']
          }
        end.reject { |idx| idx[:name].end_with?('_pkey') }
      end

      # Fetch all foreign keys from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of foreign key hashes with :table, :name, :column, :foreign_table, :foreign_column, :on_update, :on_delete
      def fetch_foreign_keys(connection)
        query = <<~SQL.squish
          SELECT
            tc.table_name,
            tc.constraint_name,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name,
            rc.update_rule,
            rc.delete_rule
          FROM information_schema.table_constraints AS tc
          JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
          JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
          JOIN information_schema.referential_constraints AS rc
            ON rc.constraint_name = tc.constraint_name
            AND rc.constraint_schema = tc.table_schema
          WHERE tc.constraint_type = 'FOREIGN KEY'
            AND tc.table_schema = 'public'
          ORDER BY tc.table_name, tc.constraint_name
        SQL

        connection.execute(query).map do |row|
          {
            table: row['table_name'],
            name: row['constraint_name'],
            column: row['column_name'],
            foreign_table: row['foreign_table_name'],
            foreign_column: row['foreign_column_name'],
            on_update: row['update_rule'],
            on_delete: row['delete_rule']
          }
        end
      end

      # Fetch all views from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of view hashes with :schema, :name, :definition
      def fetch_views(connection)
        query = <<~SQL.squish
          SELECT
            schemaname,
            viewname,
            definition
          FROM pg_views
          WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY viewname
        SQL

        connection.execute(query).map do |row|
          {
            schema: row['schemaname'],
            name: row['viewname'],
            definition: row['definition']
          }
        end
      end

      # Fetch all materialized views from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of materialized view hashes with :schema, :name, :definition, :indexes
      def fetch_materialized_views(connection)
        query = <<~SQL.squish
          SELECT
            schemaname,
            matviewname,
            definition
          FROM pg_matviews
          WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY matviewname
        SQL

        connection.execute(query).map do |row|
          {
            schema: row['schemaname'],
            name: row['matviewname'],
            definition: row['definition'],
            indexes: fetch_materialized_view_indexes(connection, row['matviewname'])
          }
        end
      end

      # Fetch all functions from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of function hashes with :schema, :name, :definition, :arguments, :return_type, :language, :volatility, :strict, :security_definer
      def fetch_functions(connection)
        query = <<~SQL.squish
          SELECT
            n.nspname as schema,
            p.proname as name,
            pg_get_functiondef(p.oid) as definition,
            pg_get_function_identity_arguments(p.oid) as arguments,
            pg_get_function_result(p.oid) as return_type,
            l.lanname as language,
            p.provolatile as volatility,
            p.proisstrict as strict,
            p.prosecdef as security_definer
          FROM pg_proc p
          JOIN pg_namespace n ON n.oid = p.pronamespace
          JOIN pg_language l ON l.oid = p.prolang
          LEFT JOIN pg_depend d ON d.objid = p.oid AND d.deptype = 'e'
          WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
            AND p.prokind = 'f'
            AND d.objid IS NULL
          ORDER BY n.nspname, p.proname
        SQL

        connection.execute(query).map do |row|
          {
            schema: row['schema'],
            name: row['name'],
            definition: row['definition'],
            arguments: row['arguments'],
            return_type: row['return_type'],
            language: row['language'],
            volatility: volatility_code(row['volatility']),
            strict: row['strict'],
            security_definer: row['security_definer']
          }
        end
      end

      # Fetch all sequences from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of sequence hashes with :name, :schema, :start_value, :increment, :min_value, :max_value, :cache_size, :cycle
      def fetch_sequences(connection)
        query = <<~SQL.squish
          SELECT
            sequencename,
            schemaname,
            start_value,
            increment_by,
            min_value,
            max_value,
            cache_size,
            cycle
          FROM pg_sequences
          WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY sequencename
        SQL

        connection.execute(query).map do |row|
          {
            name: row['sequencename'],
            schema: row['schemaname'],
            start_value: row['start_value'],
            increment: row['increment_by'],
            min_value: row['min_value'],
            max_value: row['max_value'],
            cache_size: row['cache_size'],
            cycle: row['cycle']
          }
        end
      end

      # Fetch all triggers from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of trigger hashes with :schema, :name, :table_name, :definition
      def fetch_triggers(connection)
        query = <<~SQL.squish
          SELECT
            n.nspname as schema,
            t.tgname as name,
            c.relname as table_name,
            pg_get_triggerdef(t.oid) as definition
          FROM pg_trigger t
          JOIN pg_class c ON c.oid = t.tgrelid
          JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE NOT t.tgisinternal
            AND n.nspname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY c.relname, t.tgname
        SQL

        connection.execute(query).map do |row|
          {
            schema: row['schema'],
            name: row['name'],
            table_name: row['table_name'],
            definition: row['definition']
          }
        end
      end

      # Fetch comments on database objects
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Hash] Hash with object types as keys (:tables, :columns, :indexes, :views, :functions)
      def fetch_comments(connection)
        {
          tables: fetch_table_comments(connection),
          columns: fetch_column_comments(connection),
          indexes: fetch_index_comments(connection),
          views: fetch_view_comments(connection),
          functions: fetch_function_comments(connection)
        }
      end

      # Capability methods - PostgreSQL supports all features

      # Indicates whether PostgreSQL supports extensions
      #
      # @return [Boolean] Always true for PostgreSQL
      def supports_extensions?
        true
      end

      # Indicates whether PostgreSQL supports materialized views
      #
      # @return [Boolean] Always true for PostgreSQL
      def supports_materialized_views?
        true
      end

      # Indicates whether PostgreSQL supports custom types
      #
      # @return [Boolean] Always true for PostgreSQL
      def supports_custom_types?
        true
      end

      # Indicates whether PostgreSQL supports domains
      #
      # @return [Boolean] Always true for PostgreSQL
      def supports_domains?
        true
      end

      # Indicates whether PostgreSQL supports functions
      #
      # @return [Boolean] Always true for PostgreSQL
      def supports_functions?
        true
      end

      # Indicates whether PostgreSQL supports triggers
      #
      # @return [Boolean] Always true for PostgreSQL
      def supports_triggers?
        true
      end

      # Indicates whether PostgreSQL supports sequences
      #
      # @return [Boolean] Always true for PostgreSQL
      def supports_sequences?
        true
      end

      # Indicates whether PostgreSQL supports comments
      #
      # @return [Boolean] Always true for PostgreSQL
      def supports_comments?
        true
      end

      # Version detection

      # Get the current PostgreSQL database version
      #
      # @return [String] Normalized version string (e.g., "14.5")
      def database_version
        @database_version ||= begin
          version_string = connection.select_value('SELECT version()')
          parse_version(version_string)
        end
      end

      # Parse PostgreSQL version string into normalized format
      #
      # @param version_string [String] Raw version string from PostgreSQL (e.g., "PostgreSQL 14.5...")
      # @return [String] Normalized version (e.g., "14.5") or "unknown" if parsing fails
      def parse_version(version_string)
        # Example: "PostgreSQL 14.5 (Ubuntu 14.5-1.pgdg20.04+1) on x86_64-pc-linux-gnu..."
        # Extract major.minor version
        match = version_string.match(/PostgreSQL (\d+\.\d+)/)
        return 'unknown' unless match

        match[1]
      end

      private

      # Helper methods for introspection

      # Fetch columns for a specific table
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_name [String] Name of the table
      # @return [Array<Hash>] Array of column hashes with :name, :type, :default, :nullable, etc.
      def fetch_columns(connection, table_name)
        query = <<~SQL.squish
          SELECT
            column_name,
            data_type,
            column_default,
            is_nullable,
            character_maximum_length,
            numeric_precision,
            numeric_scale,
            udt_name
          FROM information_schema.columns
          WHERE table_name = $1
            AND table_schema = 'public'
          ORDER BY ordinal_position
        SQL

        connection.select_all(
          query.gsub('$1', connection.quote(table_name))
        ).map do |row|
          {
            name: row['column_name'],
            type: resolve_column_type(row),
            default: row['column_default'],
            nullable: row['is_nullable'] == 'YES',
            length: row['character_maximum_length'],
            precision: row['numeric_precision'],
            scale: row['numeric_scale']
          }
        end
      end

      # Fetch primary key columns for a specific table
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_name [String] Name of the table
      # @return [Array<String>] Array of primary key column names
      def fetch_primary_key(connection, table_name)
        query = <<~SQL.squish
          SELECT a.attname as column_name
          FROM pg_index i
          JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
          WHERE i.indrelid = $1::regclass
            AND i.indisprimary
          ORDER BY a.attnum
        SQL

        result = connection.select_all(
          query.gsub('$1', connection.quote(table_name))
        )
        result.pluck('column_name')
      end

      # Fetch constraints (CHECK, UNIQUE) for a specific table
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_name [String] Name of the table
      # @return [Array<Hash>] Array of constraint hashes with :name, :definition, :type
      def fetch_constraints(connection, table_name)
        query = <<~SQL.squish
          SELECT
            conname as name,
            pg_get_constraintdef(oid) as definition,
            contype as type
          FROM pg_constraint
          WHERE conrelid = $1::regclass
            AND contype IN ('c', 'u')
          ORDER BY conname
        SQL

        connection.select_all(
          query.gsub('$1', connection.quote(table_name))
        ).map do |row|
          {
            name: row['name'],
            definition: row['definition'],
            type: constraint_type(row['type'])
          }
        end
      end

      # Batch fetch all columns for multiple tables (performance optimization)
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_names [Array<String>] Array of table names
      # @return [Hash<String, Array<Hash>>] Hash of table_name => array of column hashes
      def fetch_all_columns(connection, table_names)
        return {} if table_names.empty?

        query = <<~SQL.squish
          SELECT
            table_name,
            column_name,
            data_type,
            column_default,
            is_nullable,
            character_maximum_length,
            numeric_precision,
            numeric_scale,
            udt_name,
            ordinal_position
          FROM information_schema.columns
          WHERE table_name IN (#{table_names.map { |t| connection.quote(t) }.join(', ')})
            AND table_schema = 'public'
          ORDER BY table_name, ordinal_position
        SQL

        result = Hash.new { |h, k| h[k] = [] }

        connection.select_all(query).each do |row|
          result[row['table_name']] << {
            name: row['column_name'],
            type: resolve_column_type(row),
            default: row['column_default'],
            nullable: row['is_nullable'] == 'YES',
            length: row['character_maximum_length'],
            precision: row['numeric_precision'],
            scale: row['numeric_scale']
          }
        end

        result
      end

      # Batch fetch all primary keys for multiple tables (performance optimization)
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_names [Array<String>] Array of table names
      # @return [Hash<String, Array<String>>] Hash of table_name => array of primary key column names
      def fetch_all_primary_keys(connection, table_names)
        return {} if table_names.empty?

        query = <<~SQL.squish
          SELECT
            c.relname as table_name,
            a.attname as column_name,
            a.attnum as column_position
          FROM pg_index i
          JOIN pg_class c ON c.oid = i.indrelid
          JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
          JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE i.indisprimary
            AND n.nspname = 'public'
            AND c.relname IN (#{table_names.map { |t| connection.quote(t) }.join(', ')})
          ORDER BY c.relname, a.attnum
        SQL

        result = Hash.new { |h, k| h[k] = [] }

        connection.select_all(query).each do |row|
          result[row['table_name']] << row['column_name']
        end

        result
      end

      # Batch fetch all constraints for multiple tables (performance optimization)
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_names [Array<String>] Array of table names
      # @return [Hash<String, Array<Hash>>] Hash of table_name => array of constraint hashes
      def fetch_all_constraints(connection, table_names)
        return {} if table_names.empty?

        query = <<~SQL.squish
          SELECT
            c.relname as table_name,
            con.conname as name,
            pg_get_constraintdef(con.oid) as definition,
            con.contype as type
          FROM pg_constraint con
          JOIN pg_class c ON c.oid = con.conrelid
          JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE con.contype IN ('c', 'u')
            AND n.nspname = 'public'
            AND c.relname IN (#{table_names.map { |t| connection.quote(t) }.join(', ')})
          ORDER BY c.relname, con.conname
        SQL

        result = Hash.new { |h, k| h[k] = [] }

        connection.select_all(query).each do |row|
          result[row['table_name']] << {
            name: row['name'],
            definition: row['definition'],
            type: constraint_type(row['type'])
          }
        end

        result
      end

      # Fetch enum values for a specific enum type
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param type_name [String] Name of the enum type
      # @return [Array<String>] Array of enum values in sort order
      def fetch_enum_values(connection, type_name)
        query = <<~SQL.squish
          SELECT e.enumlabel
          FROM pg_enum e
          JOIN pg_type t ON t.oid = e.enumtypid
          WHERE t.typname = $1
          ORDER BY e.enumsortorder
        SQL

        connection.select_all(
          query.gsub('$1', connection.quote(type_name))
        ).pluck('enumlabel')
      end

      # Fetch attributes for a composite type
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param type_name [String] Name of the composite type
      # @return [Array<Hash>] Array of attribute hashes with :name, :type
      def fetch_composite_attributes(connection, type_name)
        query = <<~SQL.squish
          SELECT
            a.attname as name,
            format_type(a.atttypid, a.atttypmod) as type
          FROM pg_attribute a
          JOIN pg_type t ON t.typrelid = a.attrelid
          WHERE t.typname = $1
            AND a.attnum > 0
            AND NOT a.attisdropped
          ORDER BY a.attnum
        SQL

        connection.select_all(
          query.gsub('$1', connection.quote(type_name))
        ).map do |row|
          { name: row['name'], type: row['type'] }
        end
      end

      # Fetch details for a domain type
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param type_name [String] Name of the domain type
      # @return [Hash] Domain details with :base_type, :constraint
      def fetch_domain_details(connection, type_name)
        query = <<~SQL.squish
          SELECT
            format_type(t.typbasetype, t.typtypmod) as base_type,
            pg_get_constraintdef(c.oid) as constraint
          FROM pg_type t
          LEFT JOIN pg_constraint c ON c.contypid = t.oid
          WHERE t.typname = $1
        SQL

        result = connection.select_all(
          query.gsub('$1', connection.quote(type_name))
        ).first
        {
          base_type: result['base_type'],
          constraint: result['constraint']
        }
      end

      # Fetch indexes for a materialized view
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param matview_name [String] Name of the materialized view
      # @return [Array<String>] Array of index definition SQL strings
      def fetch_materialized_view_indexes(connection, matview_name)
        query = <<~SQL.squish
          SELECT indexdef
          FROM pg_indexes
          WHERE tablename = $1
          ORDER BY indexname
        SQL

        connection.select_all(
          query.gsub('$1', connection.quote(matview_name))
        ).pluck('indexdef')
      end

      # Resolve PostgreSQL column type into normalized format
      #
      # @param row [Hash] Column information row from information_schema.columns
      # @return [String] Normalized column type with length/precision if applicable
      def resolve_column_type(row)
        case row['data_type']
        when 'ARRAY'
          # For arrays, udt_name contains the base type with leading underscore (e.g., _varchar)
          base_type = row['udt_name'].sub(/^_/, '')
          "#{base_type}[]"
        when 'character varying'
          row['character_maximum_length'] ? "varchar(#{row['character_maximum_length']})" : 'varchar'
        when 'character'
          row['character_maximum_length'] ? "char(#{row['character_maximum_length']})" : 'char'
        when 'numeric'
          if row['numeric_precision'] && row['numeric_scale']
            "numeric(#{row['numeric_precision']},#{row['numeric_scale']})"
          else
            'numeric'
          end
        when 'timestamp without time zone'
          'timestamp'
        when 'timestamp with time zone'
          'timestamptz'
        when 'time without time zone'
          'time'
        when 'USER-DEFINED'
          row['udt_name']
        else
          row['data_type']
        end
      end

      # Convert PostgreSQL constraint type code to symbol
      #
      # @param type_code [String] PostgreSQL constraint type code ('c' = check, 'u' = unique)
      # @return [Symbol] Constraint type (:check, :unique, :unknown)
      def constraint_type(type_code)
        case type_code
        when 'c' then :check
        when 'u' then :unique
        else :unknown
        end
      end

      # Convert PostgreSQL type code to category string
      #
      # @param type_code [String] PostgreSQL type code ('e' = enum, 'c' = composite, 'd' = domain)
      # @return [String] Type category ('enum', 'composite', 'domain', 'unknown')
      def type_category(type_code)
        case type_code
        when 'e' then 'enum'
        when 'c' then 'composite'
        when 'd' then 'domain'
        else 'unknown'
        end
      end

      # Convert PostgreSQL volatility code to string
      #
      # @param code [String] PostgreSQL volatility code ('i' = immutable, 's' = stable, 'v' = volatile)
      # @return [String] Volatility string ('IMMUTABLE', 'STABLE', 'VOLATILE')
      def volatility_code(code)
        case code
        when 'i' then 'IMMUTABLE'
        when 's' then 'STABLE'
        when 'v' then 'VOLATILE'
        else 'VOLATILE'
        end
      end

      # SQL query for fetching custom types
      #
      # @return [String] SQL query string
      def custom_types_query
        <<~SQL.squish
          SELECT
            t.typname as name,
            t.typtype as type,
            n.nspname as schema
          FROM pg_type t
          JOIN pg_namespace n ON n.oid = t.typnamespace
          LEFT JOIN pg_class c ON c.reltype = t.oid AND c.relkind IN ('r', 'v', 'm')
          WHERE t.typtype IN ('e', 'c', 'd')
            AND n.nspname NOT IN ('pg_catalog', 'information_schema')
            AND c.oid IS NULL
          ORDER BY t.typname
        SQL
      end

      # Build custom type hash from query row
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param row [Hash] Row from custom_types_query
      # @return [Hash] Type hash with name, schema, type, and type-specific attributes
      def build_custom_type(connection, row)
        type_data = {
          name: row['schema'] == 'public' ? row['name'] : "#{row['schema']}.#{row['name']}",
          schema: row['schema'],
          type: type_category(row['type'])
        }

        case row['type']
        when 'e'
          type_data[:values] = fetch_enum_values(connection, row['name'])
        when 'c'
          type_data[:attributes] = fetch_composite_attributes(connection, row['name'])
        when 'd'
          type_data.merge!(fetch_domain_details(connection, row['name']))
        end

        type_data
      end

      # Fetch comments on tables
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Hash<String, String>] Hash of table_name => comment
      def fetch_table_comments(connection)
        query = <<~SQL.squish
          SELECT
            c.relname as table_name,
            d.description as comment
          FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = 0
          WHERE c.relkind = 'r'
            AND n.nspname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY c.relname
        SQL

        result = {}
        connection.execute(query).each do |row|
          result[row['table_name']] = row['comment']
        end
        result
      end

      # Fetch comments on columns
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Hash<String, String>] Hash of "table_name.column_name" => comment
      def fetch_column_comments(connection)
        query = <<~SQL.squish
          SELECT
            c.relname as table_name,
            a.attname as column_name,
            d.description as comment
          FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          JOIN pg_attribute a ON a.attrelid = c.oid
          JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = a.attnum
          WHERE c.relkind = 'r'
            AND n.nspname NOT IN ('pg_catalog', 'information_schema')
            AND a.attnum > 0
            AND NOT a.attisdropped
          ORDER BY c.relname, a.attnum
        SQL

        result = {}
        connection.execute(query).each do |row|
          key = "#{row['table_name']}.#{row['column_name']}"
          result[key] = row['comment']
        end
        result
      end

      # Fetch comments on indexes
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Hash<String, String>] Hash of index_name => comment
      def fetch_index_comments(connection)
        query = <<~SQL.squish
          SELECT
            c.relname as index_name,
            d.description as comment
          FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = 0
          WHERE c.relkind = 'i'
            AND n.nspname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY c.relname
        SQL

        result = {}
        connection.execute(query).each do |row|
          result[row['index_name']] = row['comment']
        end
        result
      end

      # Fetch comments on views
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Hash<String, String>] Hash of view_name => comment
      def fetch_view_comments(connection)
        query = <<~SQL.squish
          SELECT
            c.relname as view_name,
            d.description as comment
          FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = 0
          WHERE c.relkind = 'v'
            AND n.nspname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY c.relname
        SQL

        result = {}
        connection.execute(query).each do |row|
          result[row['view_name']] = row['comment']
        end
        result
      end

      # Fetch comments on functions
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Hash<String, String>] Hash of function_name => comment
      def fetch_function_comments(connection)
        query = <<~SQL.squish
          SELECT
            p.proname as function_name,
            d.description as comment
          FROM pg_proc p
          JOIN pg_namespace n ON n.oid = p.pronamespace
          JOIN pg_description d ON d.objoid = p.oid
          WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY p.proname
        SQL

        result = {}
        connection.execute(query).each do |row|
          result[row['function_name']] = row['comment']
        end
        result
      end
    end
  end
end
