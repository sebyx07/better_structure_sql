# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    module Functions
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

      private

      def volatility_code(code)
        case code
        when 'i' then 'IMMUTABLE'
        when 's' then 'STABLE'
        when 'v' then 'VOLATILE'
        else 'VOLATILE'
        end
      end
    end
  end
end
