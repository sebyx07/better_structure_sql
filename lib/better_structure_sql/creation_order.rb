# frozen_string_literal: true

module BetterStructureSql
  # Orders custom types, functions, views and materialized views so each one is
  # created after the objects it depends on.
  #
  # A fixed "functions, then tables, then views" order cannot load a function
  # returning SETOF a table or view, nor a view built on a materialized view.
  # PostgreSQL records these dependencies in pg_depend; other databases expose
  # none, which keeps their fixed order.
  class CreationOrder
    RELATION_PREFIX = 'relation:'
    FUNCTION_PREFIX = 'function:'
    TYPE_PREFIX = 'type:'

    # Dependencies of views, materialized views, routines and custom types (enums,
    # composites, ranges, domains) on relations, sequences, routines and custom types:
    #   - views and materialized views: their rewrite rule's references
    #   - routines: signature types and BEGIN ATOMIC bodies
    #   - domains and ranges: base type, subtype, canonical / subtype_diff functions
    #   - domain CHECK constraints: the functions and types their expression uses
    #   - composite types: their attribute types
    # Arrays count as their element type. Row types of tables and views count as
    # the relation; sequences count as relations (they are created before tables).
    POSTGRESQL_DEPENDENCIES_SQL = <<~SQL.freeze
      WITH raw AS (
        SELECT 'pg_class'::regclass AS classid, r.ev_class AS objid, d.refclassid, d.refobjid
        FROM pg_depend d
        JOIN pg_rewrite r ON r.oid = d.objid
        WHERE d.classid = 'pg_rewrite'::regclass
        UNION
        SELECT d.classid, d.objid, d.refclassid, d.refobjid
        FROM pg_depend d
        WHERE d.classid IN ('pg_proc'::regclass, 'pg_type'::regclass) AND d.deptype = 'n'
        UNION
        SELECT 'pg_type'::regclass, con.contypid, d.refclassid, d.refobjid
        FROM pg_depend d
        JOIN pg_constraint con ON con.oid = d.objid
        WHERE d.classid = 'pg_constraint'::regclass AND con.contypid <> 0 AND d.deptype = 'n'
        UNION
        SELECT 'pg_type'::regclass, t.oid, 'pg_type'::regclass, a.atttypid
        FROM pg_type t
        JOIN pg_class c ON c.oid = t.typrelid AND c.relkind = 'c'
        JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped
      ), element_resolved AS (
        SELECT raw.classid, raw.objid, raw.refclassid,
               CASE WHEN element.oid IS NULL THEN raw.refobjid ELSE element.oid END AS refobjid
        FROM raw
        LEFT JOIN pg_type element ON raw.refclassid = 'pg_type'::regclass AND element.typarray = raw.refobjid
      ), resolved AS (
        SELECT e.classid, e.objid,
               CASE WHEN rowtype.oid IS NULL THEN e.refclassid ELSE 'pg_class'::regclass END AS refclassid,
               COALESCE(rowtype.oid, e.refobjid) AS refobjid
        FROM element_resolved e
        LEFT JOIN pg_type t ON e.refclassid = 'pg_type'::regclass AND t.oid = e.refobjid
        LEFT JOIN pg_class rowtype ON rowtype.oid = t.typrelid AND rowtype.relkind <> 'c'
      )
      SELECT DISTINCT
        COALESCE('#{RELATION_PREFIX}' || dc.relname,
                 '#{FUNCTION_PREFIX}' || dp.proname || '(' || pg_get_function_identity_arguments(dp.oid) || ')',
                 '#{TYPE_PREFIX}' || dt.typname) AS name,
        COALESCE('#{RELATION_PREFIX}' || rc.relname,
                 '#{FUNCTION_PREFIX}' || rp.proname || '(' || pg_get_function_identity_arguments(rp.oid) || ')',
                 '#{TYPE_PREFIX}' || rt.typname) AS depends_on
      FROM resolved e
      LEFT JOIN pg_class dc ON e.classid = 'pg_class'::regclass AND dc.oid = e.objid
        AND dc.relnamespace = %<schema>s::regnamespace
      LEFT JOIN pg_proc dp ON e.classid = 'pg_proc'::regclass AND dp.oid = e.objid
        AND dp.pronamespace = %<schema>s::regnamespace
      LEFT JOIN pg_type dt ON e.classid = 'pg_type'::regclass AND dt.oid = e.objid
        AND dt.typnamespace = %<schema>s::regnamespace AND dt.typtype IN ('e', 'c', 'd', 'r')
      LEFT JOIN pg_class rc ON e.refclassid = 'pg_class'::regclass AND rc.oid = e.refobjid
        AND rc.relnamespace = %<schema>s::regnamespace AND rc.relkind IN ('r', 'p', 'f', 'v', 'm', 'S')
      LEFT JOIN pg_proc rp ON e.refclassid = 'pg_proc'::regclass AND rp.oid = e.refobjid
        AND rp.pronamespace = %<schema>s::regnamespace
      LEFT JOIN pg_type rt ON e.refclassid = 'pg_type'::regclass AND rt.oid = e.refobjid
        AND rt.typnamespace = %<schema>s::regnamespace AND rt.typtype IN ('e', 'c', 'd', 'r')
      WHERE (dc.oid IS NOT NULL OR dp.oid IS NOT NULL OR dt.oid IS NOT NULL)
        AND (rc.oid IS NOT NULL OR rp.oid IS NOT NULL OR rt.oid IS NOT NULL)
        AND NOT (e.classid = e.refclassid AND e.objid = e.refobjid)
      ORDER BY 1, 2
    SQL

    # Builds the creation order for a database
    #
    # @param adapter [Adapters::BaseAdapter] Adapter of the database being dumped
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
    # @return [CreationOrder]
    def self.for(adapter, connection)
      return new({}) unless adapter.class.name == 'BetterStructureSql::Adapters::PostgresqlAdapter'

      sql = format(POSTGRESQL_DEPENDENCIES_SQL, schema: connection.quote(Adapters::PostgresqlAdapter::DUMPED_SCHEMA))
      new(connection.select_rows(sql).group_by(&:first).transform_values { |rows| rows.map(&:last) })
    end

    # @param name [String] View, materialized view or table name
    # @return [String] Dependency key
    def self.relation_key(name)
      "#{RELATION_PREFIX}#{name}"
    end

    # @param name [String] Enum, composite, range or domain name
    # @return [String] Dependency key
    def self.type_key(name)
      "#{TYPE_PREFIX}#{name}"
    end

    # @param function [Hash] Function hash with :name and :arguments
    # @return [String] Dependency key
    def self.function_key(function)
      "#{FUNCTION_PREFIX}#{function[:name]}(#{function[:arguments]})"
    end

    # @param dependencies [Hash<String, Array<String>>] Dependency key => keys it depends on
    def initialize(dependencies)
      @dependencies = dependencies
    end

    # Whether an object needs a relation (or sequence) to exist, directly or through other objects
    #
    # @param key [String] Dependency key
    # @return [Boolean]
    def needs_relation?(key)
      needs?(key, RELATION_PREFIX)
    end

    # Whether an object needs a routine to exist, directly or through other objects
    #
    # @param key [String] Dependency key
    # @return [Boolean]
    def needs_function?(key)
      needs?(key, FUNCTION_PREFIX)
    end

    # Sorts objects so dependencies come first, otherwise keeping the given order
    #
    # @param keyed_objects [Array<Array(String, Object)>] Pairs of dependency key and object
    # @return [Array<Object>] Objects in creation order
    def sort(keyed_objects)
      return keyed_objects.map(&:last) if @dependencies.empty?

      resolver = DependencyResolver.new
      objects = keyed_objects.to_h
      objects.each_key { |key| resolver.add_object(key, :object, depends_on: @dependencies.fetch(key, [])) }

      resolver.resolve.map { |key| objects.fetch(key) }
    end

    private

    def needs?(key, prefix, seen = Set.new)
      return false unless seen.add?(key)

      @dependencies.fetch(key, []).any? { |dependency| dependency.start_with?(prefix) || needs?(dependency, prefix, seen) }
    end
  end
end
