# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # PostgreSQL adapter implementing all introspection and generation methods
    #
    # Provides full PostgreSQL support including extensions, custom types, materialized views,
    # functions, triggers, sequences, partitioned tables and all standard database objects.
    #
    # Introspection reads pg_catalog directly and relies on PostgreSQL's own deparse
    # functions (format_type, pg_get_expr, pg_get_constraintdef, pg_get_indexdef, ...)
    # so the generated SQL matches what the server understands. Objects owned by
    # extensions are skipped because CREATE EXTENSION recreates them.
    class PostgresqlAdapter < BaseAdapter
      # Schema whose objects are dumped. Extensions may live in any schema.
      DUMPED_SCHEMA = 'public'

      # Rewrites format_type output into the short type names used in dumps
      TYPE_ALIASES = [
        [/\Acharacter varying/, 'varchar'],
        [/\Acharacter(?=\(|\[|\z)/, 'char'],
        [/\Atimestamp(\(\d+\))? without time zone/, 'timestamp\1'],
        [/\Atimestamp(\(\d+\))? with time zone/, 'timestamptz\1'],
        [/\Atime(\(\d+\))? without time zone/, 'time\1']
      ].freeze

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

      # Fetch all custom types (enums, composite types, domains, ranges) from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of type hashes with :name, :schema, :type, and type-specific attributes
      def fetch_custom_types(connection)
        connection.select_all(custom_types_query).map { |row| build_custom_type(connection, row) }
      end

      # Fetch all tables from the database
      #
      # Partitions are not returned at the top level: each partition is nested under
      # its parent's :partitions so it is always created after the parent.
      # Batches all table metadata queries to avoid N+1 queries.
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of table hashes with :name, :schema, :columns, :primary_key, :constraints
      def fetch_tables(connection)
        table_rows = connection.select_all(tables_query).to_a
        return [] if table_rows.empty?

        oids = table_rows.pluck('oid')
        columns = fetch_all_columns(connection, oids)
        constraints = fetch_all_constraints(connection, oids)
        sequences = fetch_owned_sequences(connection, oids)

        tables = table_rows.to_h do |row|
          [row['oid'], build_table(row, columns, constraints, sequences)]
        end
        nest_partitions(table_rows, tables)
      end

      # Fetch all indexes that are not created by a constraint or a parent partitioned index
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of index hashes with :schema, :table, :name, :definition
      def fetch_indexes(connection)
        query = <<~SQL.squish
          SELECT
            n.nspname AS schemaname,
            t.relname AS tablename,
            ic.relname AS indexname,
            ic.relkind = 'I' AS partitioned,
            pg_get_indexdef(i.indexrelid) AS indexdef
          FROM pg_index i
          JOIN pg_class ic ON ic.oid = i.indexrelid
          JOIN pg_class t ON t.oid = i.indrelid
          JOIN pg_namespace n ON n.oid = t.relnamespace
          WHERE n.nspname = '#{DUMPED_SCHEMA}'
            AND t.relkind IN ('r', 'p')
            AND NOT ic.relispartition
            AND NOT EXISTS (
              SELECT 1 FROM pg_constraint con
              WHERE con.conindid = i.indexrelid AND con.contype IN ('p', 'u', 'x')
            )
            AND #{not_extension_member('t.oid')}
          ORDER BY t.relname, ic.relname
        SQL

        connection.select_all(query).map do |row|
          {
            schema: row['schemaname'],
            table: row['tablename'],
            name: row['indexname'],
            definition: index_definition(row)
          }
        end
      end

      # Fetch all foreign keys from the database
      #
      # Foreign keys cloned onto partitions are skipped; the parent's constraint recreates them.
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of foreign key hashes with :table, :schema, :name, :definition
      def fetch_foreign_keys(connection)
        query = <<~SQL.squish
          SELECT
            c.relname AS table_name,
            n.nspname AS schema_name,
            con.conname AS constraint_name,
            pg_get_constraintdef(con.oid) AS definition
          FROM pg_constraint con
          JOIN pg_class c ON c.oid = con.conrelid
          JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE con.contype = 'f'
            AND con.conparentid = 0
            AND n.nspname = '#{DUMPED_SCHEMA}'
            AND #{not_extension_member('c.oid')}
          ORDER BY c.relname, con.conname
        SQL

        connection.select_all(query).map do |row|
          {
            table: row['table_name'],
            schema: row['schema_name'],
            name: row['constraint_name'],
            definition: row['definition']
          }
        end
      end

      # Fetch all views from the database, ordered so dependencies come first
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of view hashes with :schema, :name, :definition, :options
      def fetch_views(connection)
        rows = connection.select_all(relations_query('v')).map do |row|
          {
            schema: row['schema_name'],
            name: row['name'],
            definition: row['definition'],
            options: row['options']
          }
        end
        order_by_dependencies(rows, fetch_relation_dependencies(connection, 'v'))
      end

      # Fetch all materialized views from the database, ordered so dependencies come first
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of materialized view hashes with :schema, :name, :definition, :indexes, :comment
      def fetch_materialized_views(connection)
        indexes = fetch_materialized_view_indexes(connection)
        comments = fetch_relation_comments(connection, %w[m])
        rows = connection.select_all(relations_query('m')).map do |row|
          {
            schema: row['schema_name'],
            name: row['name'],
            definition: row['definition'],
            indexes: indexes[row['name']],
            comment: comments[row['name']]
          }
        end
        order_by_dependencies(rows, fetch_relation_dependencies(connection, 'm'))
      end

      # Fetch all functions and procedures from the database
      #
      # Skips extension members and functions created implicitly by a type
      # (e.g. range type constructors).
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
          WHERE n.nspname = '#{DUMPED_SCHEMA}'
            AND p.prokind IN ('f', 'p', 'w')
            AND NOT EXISTS (
              SELECT 1 FROM pg_depend d
              WHERE d.classid = 'pg_proc'::regclass AND d.objid = p.oid AND d.deptype IN ('e', 'i')
            )
          ORDER BY n.nspname, p.proname, pg_get_function_identity_arguments(p.oid)
        SQL

        connection.select_all(query).map do |row|
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

      # Fetch standalone and serial sequences from the database
      #
      # Identity sequences are skipped: they are recreated by the identity column.
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of sequence hashes with :name, :schema, :data_type, :start_value, :increment, :min_value, :max_value, :cache_size, :cycle
      def fetch_sequences(connection)
        query = <<~SQL.squish
          SELECT
            s.sequencename,
            s.schemaname,
            s.data_type::text AS data_type,
            s.start_value,
            s.increment_by,
            s.min_value,
            s.max_value,
            s.cache_size,
            s.cycle
          FROM pg_sequences s
          JOIN pg_namespace n ON n.nspname = s.schemaname
          JOIN pg_class c ON c.relname = s.sequencename AND c.relnamespace = n.oid
          WHERE s.schemaname = '#{DUMPED_SCHEMA}'
            AND NOT EXISTS (
              SELECT 1 FROM pg_depend d
              WHERE d.classid = 'pg_class'::regclass AND d.objid = c.oid AND d.deptype IN ('e', 'i')
            )
          ORDER BY s.sequencename
        SQL

        connection.select_all(query).map { |row| build_sequence(row) }
      end

      # Fetch all user triggers from the database
      #
      # Triggers cloned onto partitions are skipped; the parent's trigger recreates them.
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
            AND n.nspname = '#{DUMPED_SCHEMA}'
            AND NOT EXISTS (
              SELECT 1 FROM pg_depend d
              WHERE d.classid = 'pg_trigger'::regclass AND d.objid = t.oid AND d.deptype IN ('e', 'P')
            )
          ORDER BY c.relname, t.tgname
        SQL

        connection.select_all(query).map do |row|
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
      # @return [Hash] Hash with object types as keys (:tables, :columns, :indexes, :views, :functions, :procedures);
      #   :columns is keyed by [table_name, column_name]
      def fetch_comments(connection)
        {
          tables: fetch_relation_comments(connection, %w[r p]),
          columns: fetch_column_comments(connection),
          indexes: fetch_relation_comments(connection, %w[i I]),
          views: fetch_relation_comments(connection, %w[v]),
          functions: fetch_routine_comments(connection, %w[f w]),
          procedures: fetch_routine_comments(connection, %w[p])
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

      # SQL condition excluding pg_class objects owned by an extension
      #
      # @param oid_column [String] Column holding the pg_class oid
      # @return [String] SQL condition
      def not_extension_member(oid_column)
        <<~SQL.squish
          NOT EXISTS (
            SELECT 1 FROM pg_depend ext
            WHERE ext.classid = 'pg_class'::regclass AND ext.objid = #{oid_column} AND ext.deptype = 'e'
          )
        SQL
      end

      # SQL listing oids as an IN list
      #
      # @param oids [Array<Integer>] Object ids
      # @return [String] Comma separated oids
      def oid_list(oids)
        oids.map { |oid| Integer(oid) }.join(', ')
      end

      # SQL query for regular and partitioned tables, with persistence, storage
      # parameters (WITH (...)) and the parents of inheritance children (INHERITS)
      #
      # @return [String] SQL query string
      def tables_query
        <<~SQL.squish
          SELECT
            c.oid,
            c.relname AS table_name,
            n.nspname AS table_schema,
            c.relispartition AS partition,
            CASE WHEN c.relkind = 'p' THEN pg_get_partkeydef(c.oid) END AS partition_key,
            pg_get_expr(c.relpartbound, c.oid) AS partition_bound,
            parent.relname AS parent_name,
            c.relpersistence = 'u' AS unlogged,
            (
              SELECT string_agg(o.option_name || '=' || CASE WHEN o.option_value ~ '^[A-Za-z0-9_.]+$'
                                                         THEN o.option_value ELSE quote_literal(o.option_value) END, ', ')
              FROM pg_options_to_table(c.reloptions) o
            ) AS storage_parameters,
            (
              SELECT json_agg(inherited.relname ORDER BY i.inhseqno)
              FROM pg_inherits i
              JOIN pg_class inherited ON inherited.oid = i.inhparent
              WHERE i.inhrelid = c.oid AND NOT c.relispartition
            ) AS inherits
          FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          LEFT JOIN pg_inherits inh ON inh.inhrelid = c.oid AND c.relispartition
          LEFT JOIN pg_class parent ON parent.oid = inh.inhparent
          WHERE c.relkind IN ('r', 'p')
            AND n.nspname = '#{DUMPED_SCHEMA}'
            AND #{not_extension_member('c.oid')}
          ORDER BY c.relname
        SQL
      end

      # Build a table hash from its row and batched metadata
      #
      # @param row [Hash] Row from tables_query
      # @param columns [Hash<Integer, Array<Hash>>] Columns by table oid
      # @param constraints [Hash<Integer, Array<Hash>>] Constraints by table oid
      # @param sequences [Hash<Integer, Array<Hash>>] Owned sequences by table oid
      # @return [Hash] Table metadata
      def build_table(row, columns, constraints, sequences)
        table_constraints = constraints[row['oid']]
        primary_key = table_constraints.find { |con| con[:type] == :primary_key }
        inherits = row['inherits'] ? JSON.parse(row['inherits']) : []

        {
          name: row['table_name'],
          schema: row['table_schema'],
          columns: local_columns(columns[row['oid']], inherits),
          primary_key: primary_key ? primary_key[:columns] : [],
          primary_key_name: primary_key&.dig(:name),
          constraints: table_constraints - [primary_key],
          partition_key: row['partition_key'],
          partition_of: row['parent_name'],
          partition_bound: row['partition_bound'],
          partitions: [],
          owned_sequences: sequences[row['oid']],
          unlogged: row['unlogged'],
          storage_parameters: row['storage_parameters'],
          inherits:
        }
      end

      # Columns an inheritance child defines itself; INHERITS recreates the rest
      #
      # @param columns [Array<Hash>] Column hashes with :local
      # @param inherits [Array<String>] Parent table names
      # @return [Array<Hash>] Column hashes without :local
      def local_columns(columns, inherits)
        columns = columns.select { |column| column[:local] } if inherits.any?
        columns.map { |column| column.except(:local) }
      end

      # Move partitions under their parent table
      #
      # @param table_rows [Array<Hash>] Rows from tables_query
      # @param tables [Hash<Integer, Hash>] Table hashes by oid
      # @return [Array<Hash>] Top-level tables
      def nest_partitions(table_rows, tables)
        by_name = tables.values.index_by { |table| table[:name] }
        table_rows.each do |row|
          by_name.fetch(row['parent_name'])[:partitions] << tables[row['oid']] if row['partition']
        end
        table_rows.reject { |row| row['partition'] }.map { |row| tables[row['oid']] }
      end

      # Batch fetch all columns for multiple tables
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param oids [Array<Integer>] Table oids
      # @return [Hash<Integer, Array<Hash>>] Hash of table oid => array of column hashes
      def fetch_all_columns(connection, oids)
        query = <<~SQL.squish
          SELECT
            a.attrelid AS table_oid,
            a.attname AS column_name,
            format_type(a.atttypid, a.atttypmod) AS data_type,
            pg_get_expr(ad.adbin, ad.adrelid) AS expression,
            NOT a.attnotnull AS nullable,
            a.attidentity AS identity,
            a.attgenerated AS generated,
            a.attislocal AS local,
            CASE WHEN a.attcollation <> t.typcollation THEN quote_ident(co.collname) END AS collation,
            seq.seqstart, seq.seqincrement, seq.seqmin, seq.seqmax, seq.seqcache, seq.seqcycle
          FROM pg_attribute a
          JOIN pg_type t ON t.oid = a.atttypid
          LEFT JOIN pg_collation co ON co.oid = a.attcollation
          LEFT JOIN pg_attrdef ad ON ad.adrelid = a.attrelid AND ad.adnum = a.attnum
          LEFT JOIN pg_depend dep ON dep.refobjid = a.attrelid AND dep.refobjsubid = a.attnum
            AND dep.classid = 'pg_class'::regclass AND dep.deptype = 'i' AND a.attidentity <> ''
          LEFT JOIN pg_sequence seq ON seq.seqrelid = dep.objid
          WHERE a.attrelid IN (#{oid_list(oids)})
            AND a.attnum > 0
            AND NOT a.attisdropped
          ORDER BY a.attrelid, a.attnum
        SQL

        result = Hash.new { |hash, key| hash[key] = [] }
        connection.select_all(query).each do |row|
          result[row['table_oid']] << build_column(row)
        end
        result
      end

      # Build a column hash from a column row
      #
      # @param row [Hash] Row from fetch_all_columns
      # @return [Hash] Column metadata
      def build_column(row)
        generated = row['generated'].presence
        {
          name: row['column_name'],
          type: normalize_type(row['data_type']),
          default: generated ? nil : row['expression'],
          nullable: row['nullable'],
          collation: row['collation'],
          generated: generated && { expression: row['expression'], kind: generated == 's' ? 'STORED' : 'VIRTUAL' },
          identity: row['identity'].presence && build_identity(row),
          local: row['local']
        }
      end

      # Build identity column metadata
      #
      # @param row [Hash] Row from fetch_all_columns
      # @return [Hash] Identity metadata with :generation and sequence options
      def build_identity(row)
        {
          generation: row['identity'] == 'a' ? 'ALWAYS' : 'BY DEFAULT',
          start_value: row['seqstart'],
          increment: row['seqincrement'],
          min_value: row['seqmin'],
          max_value: row['seqmax'],
          cache_size: row['seqcache'],
          cycle: row['seqcycle']
        }
      end

      # Shorten format_type output to the type names used in dumps
      #
      # @param type [String] format_type output (e.g. "character varying(255)[]")
      # @return [String] Normalized type (e.g. "varchar(255)[]")
      def normalize_type(type)
        TYPE_ALIASES.reduce(type) { |result, (pattern, replacement)| result.sub(pattern, replacement) }
      end

      # Batch fetch primary key, unique, check and exclusion constraints
      #
      # Constraints a partition or an inheritance child inherits from its parent are skipped.
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param oids [Array<Integer>] Table oids
      # @return [Hash<Integer, Array<Hash>>] Hash of table oid => array of constraint hashes
      def fetch_all_constraints(connection, oids)
        query = <<~SQL.squish
          SELECT
            con.conrelid AS table_oid,
            con.conname AS name,
            pg_get_constraintdef(con.oid) AS definition,
            con.contype AS type,
            con.convalidated AS validated,
            (
              SELECT json_agg(a.attname ORDER BY k.position)
              FROM unnest(con.conkey) WITH ORDINALITY AS k(attnum, position)
              JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = k.attnum
            ) AS columns
          FROM pg_constraint con
          JOIN pg_class rel ON rel.oid = con.conrelid
          WHERE con.conrelid IN (#{oid_list(oids)})
            AND con.contype IN ('p', 'u', 'c', 'x')
            AND con.conparentid = 0
            AND con.conislocal
            AND (NOT rel.relispartition OR con.coninhcount = 0)
          ORDER BY con.conrelid, con.conname
        SQL

        result = Hash.new { |hash, key| hash[key] = [] }
        connection.select_all(query).each do |row|
          result[row['table_oid']] << {
            name: row['name'],
            definition: row['definition'],
            type: constraint_type(row['type']),
            validated: row['validated'],
            columns: row['columns'] ? JSON.parse(row['columns']) : []
          }
        end
        result
      end

      # Batch fetch serial sequences owned by table columns (OWNED BY)
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param oids [Array<Integer>] Table oids
      # @return [Hash<Integer, Array<Hash>>] Hash of table oid => array of :sequence, :column hashes
      def fetch_owned_sequences(connection, oids)
        query = <<~SQL.squish
          SELECT dep.refobjid AS table_oid, s.relname AS sequence_name, a.attname AS column_name
          FROM pg_depend dep
          JOIN pg_class s ON s.oid = dep.objid AND s.relkind = 'S'
          JOIN pg_attribute a ON a.attrelid = dep.refobjid AND a.attnum = dep.refobjsubid
          WHERE dep.classid = 'pg_class'::regclass
            AND dep.refclassid = 'pg_class'::regclass
            AND dep.deptype = 'a'
            AND dep.refobjid IN (#{oid_list(oids)})
          ORDER BY s.relname
        SQL

        result = Hash.new { |hash, key| hash[key] = [] }
        connection.select_all(query).each do |row|
          result[row['table_oid']] << { sequence: row['sequence_name'], column: row['column_name'] }
        end
        result
      end

      # Build a sequence hash from a pg_sequences row
      #
      # @param row [Hash] Row from fetch_sequences
      # @return [Hash] Sequence metadata
      def build_sequence(row)
        {
          name: row['sequencename'],
          schema: row['schemaname'],
          data_type: row['data_type'],
          start_value: row['start_value'],
          increment: row['increment_by'],
          min_value: row['min_value'],
          max_value: row['max_value'],
          cache_size: row['cache_size'],
          cycle: row['cycle']
        }
      end

      # Render an index definition that recreates the index on every partition
      #
      # pg_get_indexdef renders indexes on partitioned tables as "ON ONLY", which
      # creates an invalid index until each partition index is attached.
      #
      # @param row [Hash] Row from fetch_indexes
      # @return [String] CREATE INDEX statement
      def index_definition(row)
        return row['indexdef'] unless row['partitioned']

        row['indexdef'].sub(' ON ONLY ', ' ON ')
      end

      # SQL query for views or materialized views
      #
      # @param relkind [String] 'v' for views, 'm' for materialized views
      # @return [String] SQL query string
      def relations_query(relkind)
        <<~SQL.squish
          SELECT
            n.nspname AS schema_name,
            c.relname AS name,
            pg_get_viewdef(c.oid) AS definition,
            array_to_string(c.reloptions, ', ') AS options
          FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE c.relkind = '#{relkind}'
            AND n.nspname = '#{DUMPED_SCHEMA}'
            AND #{not_extension_member('c.oid')}
          ORDER BY c.relname
        SQL
      end

      # Fetch which views (or materialized views) reference each other
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param relkind [String] 'v' for views, 'm' for materialized views
      # @return [Hash<String, Array<String>>] Hash of relation name => names it depends on
      def fetch_relation_dependencies(connection, relkind)
        query = <<~SQL.squish
          SELECT DISTINCT dependent.relname AS name, referenced.relname AS depends_on
          FROM pg_depend d
          JOIN pg_rewrite r ON r.oid = d.objid
          JOIN pg_class dependent ON dependent.oid = r.ev_class
          JOIN pg_class referenced ON referenced.oid = d.refobjid
          JOIN pg_namespace n ON n.oid = dependent.relnamespace
          WHERE d.classid = 'pg_rewrite'::regclass
            AND d.refclassid = 'pg_class'::regclass
            AND dependent.oid <> referenced.oid
            AND dependent.relkind = '#{relkind}'
            AND referenced.relkind = '#{relkind}'
            AND n.nspname = '#{DUMPED_SCHEMA}'
          ORDER BY 1, 2
        SQL

        connection.select_all(query).each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |row, deps|
          deps[row['name']] << row['depends_on']
        end
      end

      # Fetch indexes for all materialized views
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Hash<String, Array<String>>] Hash of materialized view name => index definitions
      def fetch_materialized_view_indexes(connection)
        query = <<~SQL.squish
          SELECT t.relname AS matview_name, pg_get_indexdef(i.indexrelid) AS indexdef
          FROM pg_index i
          JOIN pg_class ic ON ic.oid = i.indexrelid
          JOIN pg_class t ON t.oid = i.indrelid
          JOIN pg_namespace n ON n.oid = t.relnamespace
          WHERE t.relkind = 'm'
            AND n.nspname = '#{DUMPED_SCHEMA}'
          ORDER BY t.relname, ic.relname
        SQL

        connection.select_all(query).each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |row, indexes|
          indexes[row['matview_name']] << row['indexdef']
        end
      end

      # Convert PostgreSQL constraint type code to symbol
      #
      # @param type_code [String] PostgreSQL constraint type code
      # @return [Symbol] Constraint type (:primary_key, :unique, :check, :exclusion, :unknown)
      def constraint_type(type_code)
        case type_code
        when 'p' then :primary_key
        when 'u' then :unique
        when 'c' then :check
        when 'x' then :exclusion
        else :unknown
        end
      end

      # Convert PostgreSQL type code to category string
      #
      # @param type_code [String] PostgreSQL type code ('e' = enum, 'c' = composite, 'd' = domain, 'r' = range)
      # @return [String] Type category ('enum', 'composite', 'domain', 'range', 'unknown')
      def type_category(type_code)
        case type_code
        when 'e' then 'enum'
        when 'c' then 'composite'
        when 'd' then 'domain'
        when 'r' then 'range'
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
      # Composite types backing tables, views and other relations are skipped,
      # as are types owned by extensions.
      #
      # @return [String] SQL query string
      def custom_types_query
        <<~SQL.squish
          SELECT
            t.oid,
            t.typname as name,
            t.typtype as type,
            n.nspname as schema
          FROM pg_type t
          JOIN pg_namespace n ON n.oid = t.typnamespace
          LEFT JOIN pg_class c ON c.oid = t.typrelid
          WHERE t.typtype IN ('e', 'c', 'd', 'r')
            AND n.nspname = '#{DUMPED_SCHEMA}'
            AND (t.typrelid = 0 OR c.relkind = 'c')
            AND NOT EXISTS (
              SELECT 1 FROM pg_depend d
              WHERE d.classid = 'pg_type'::regclass AND d.objid = t.oid AND d.deptype = 'e'
            )
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
          name: row['name'],
          schema: row['schema'],
          type: type_category(row['type'])
        }

        case row['type']
        when 'e'
          type_data[:values] = fetch_enum_values(connection, row['oid'])
        when 'c'
          type_data[:attributes] = fetch_composite_attributes(connection, row['oid'])
        when 'd'
          type_data.merge!(fetch_domain_details(connection, row['oid']))
        when 'r'
          type_data.merge!(fetch_range_details(connection, row['oid']))
        end

        type_data
      end

      # Fetch enum values for an enum type
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param type_oid [Integer] Enum type oid
      # @return [Array<String>] Array of enum values in sort order
      def fetch_enum_values(connection, type_oid)
        query = <<~SQL.squish
          SELECT enumlabel FROM pg_enum WHERE enumtypid = #{Integer(type_oid)} ORDER BY enumsortorder
        SQL

        connection.select_all(query).pluck('enumlabel')
      end

      # Fetch attributes for a composite type
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param type_oid [Integer] Composite type oid
      # @return [Array<Hash>] Array of attribute hashes with :name, :type
      def fetch_composite_attributes(connection, type_oid)
        query = <<~SQL.squish
          SELECT a.attname AS name, format_type(a.atttypid, a.atttypmod) AS type
          FROM pg_attribute a
          JOIN pg_type t ON t.typrelid = a.attrelid
          WHERE t.oid = #{Integer(type_oid)}
            AND a.attnum > 0
            AND NOT a.attisdropped
          ORDER BY a.attnum
        SQL

        connection.select_all(query).map do |row|
          { name: row['name'], type: row['type'] }
        end
      end

      # Fetch details for a domain type
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param type_oid [Integer] Domain type oid
      # @return [Hash] Domain details with :base_type, :default, :not_null, :constraints
      def fetch_domain_details(connection, type_oid)
        query = <<~SQL.squish
          SELECT
            format_type(t.typbasetype, t.typtypmod) AS base_type,
            t.typdefault AS default_value,
            t.typnotnull AS not_null
          FROM pg_type t
          WHERE t.oid = #{Integer(type_oid)}
        SQL

        row = connection.select_all(query).first
        {
          base_type: row['base_type'],
          default: row['default_value'],
          not_null: row['not_null'],
          constraints: fetch_domain_constraints(connection, type_oid)
        }
      end

      # Fetch CHECK constraints of a domain
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param type_oid [Integer] Domain type oid
      # @return [Array<Hash>] Array of constraint hashes with :name, :definition
      def fetch_domain_constraints(connection, type_oid)
        query = <<~SQL.squish
          SELECT conname AS name, pg_get_constraintdef(oid) AS definition
          FROM pg_constraint
          WHERE contypid = #{Integer(type_oid)} AND contype = 'c'
          ORDER BY conname
        SQL

        connection.select_all(query).map do |row|
          { name: row['name'], definition: row['definition'] }
        end
      end

      # Fetch details for a range type
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param type_oid [Integer] Range type oid
      # @return [Hash] Range details with :subtype, :subtype_opclass, :collation, :canonical, :subtype_diff
      def fetch_range_details(connection, type_oid)
        query = <<~SQL.squish
          SELECT
            format_type(r.rngsubtype, NULL) AS subtype,
            CASE WHEN NOT opc.opcdefault THEN quote_ident(opc.opcname) END AS subtype_opclass,
            CASE WHEN r.rngcollation <> st.typcollation THEN quote_ident(co.collname) END AS collation,
            NULLIF(r.rngcanonical, 0)::regproc::text AS canonical,
            NULLIF(r.rngsubdiff, 0)::regproc::text AS subtype_diff
          FROM pg_range r
          JOIN pg_type st ON st.oid = r.rngsubtype
          JOIN pg_opclass opc ON opc.oid = r.rngsubopc
          LEFT JOIN pg_collation co ON co.oid = r.rngcollation
          WHERE r.rngtypid = #{Integer(type_oid)}
        SQL

        connection.select_all(query).first.symbolize_keys
      end

      # Fetch comments on relations of the given kinds
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param relkinds [Array<String>] pg_class relkind codes
      # @return [Hash<String, String>] Hash of relation name => comment
      def fetch_relation_comments(connection, relkinds)
        query = <<~SQL.squish
          SELECT c.relname AS name, d.description AS comment
          FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          JOIN pg_description d ON d.objoid = c.oid AND d.classoid = 'pg_class'::regclass AND d.objsubid = 0
          WHERE c.relkind IN (#{relkinds.map { |kind| "'#{kind}'" }.join(', ')})
            AND n.nspname = '#{DUMPED_SCHEMA}'
            AND #{not_extension_member('c.oid')}
          ORDER BY c.relname
        SQL

        connection.select_all(query).to_h { |row| [row['name'], row['comment']] }
      end

      # Fetch comments on table and view columns
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Hash<Array(String, String), String>] Hash of [table_name, column_name] => comment
      def fetch_column_comments(connection)
        query = <<~SQL.squish
          SELECT
            c.relname as table_name,
            a.attname as column_name,
            d.description as comment
          FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          JOIN pg_attribute a ON a.attrelid = c.oid
          JOIN pg_description d ON d.objoid = c.oid AND d.classoid = 'pg_class'::regclass AND d.objsubid = a.attnum
          WHERE c.relkind IN ('r', 'p', 'v', 'm')
            AND n.nspname = '#{DUMPED_SCHEMA}'
            AND a.attnum > 0
            AND NOT a.attisdropped
            AND #{not_extension_member('c.oid')}
          ORDER BY c.relname, a.attnum
        SQL

        connection.select_all(query).to_h do |row|
          [[row['table_name'], row['column_name']], row['comment']]
        end
      end

      # Fetch comments on functions or procedures
      #
      # Keys are full signatures (e.g. "add(integer, integer)") so overloads keep
      # their own comment and the COMMENT ON statement is unambiguous.
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param prokinds [Array<String>] pg_proc prokind codes ('f' function, 'w' window, 'p' procedure)
      # @return [Hash<String, String>] Hash of routine signature => comment
      def fetch_routine_comments(connection, prokinds)
        query = <<~SQL.squish
          SELECT
            format('%I(%s)', p.proname, pg_get_function_identity_arguments(p.oid)) AS signature,
            d.description AS comment
          FROM pg_proc p
          JOIN pg_namespace n ON n.oid = p.pronamespace
          JOIN pg_description d ON d.objoid = p.oid AND d.classoid = 'pg_proc'::regclass
          WHERE n.nspname = '#{DUMPED_SCHEMA}'
            AND p.prokind IN (#{prokinds.map { |kind| connection.quote(kind) }.join(', ')})
            AND NOT EXISTS (
              SELECT 1 FROM pg_depend dep
              WHERE dep.classid = 'pg_proc'::regclass AND dep.objid = p.oid AND dep.deptype = 'e'
            )
          ORDER BY 1
        SQL

        connection.select_all(query).to_h { |row| [row['signature'], row['comment']] }
      end
    end
  end
end
