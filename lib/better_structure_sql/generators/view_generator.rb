# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Generates CREATE VIEW statements
    class ViewGenerator < Base
      # Generates CREATE VIEW statement
      #
      # Views carrying their original CREATE VIEW statement (:sql, supplied by
      # the SQLite adapter) are emitted verbatim: SQLite has no CREATE OR
      # REPLACE VIEW, and replaying the stored statement keeps sqlite_master
      # identical after a load.
      #
      # @param view [Hash] View metadata with definition and optional :options
      #   (PostgreSQL reloptions such as "check_option=local, security_barrier=true")
      #   and :sql (original CREATE VIEW statement)
      # @return [String] SQL statement
      def generate(view)
        return "#{view[:sql]};" if view[:sql]

        definition = view[:definition].strip

        # Ensure definition ends with semicolon
        definition += ';' unless definition.end_with?(';')

        options = view[:options].present? ? " WITH (#{view[:options]})" : ''
        "CREATE OR REPLACE VIEW #{qualified_identifier(view[:schema], view[:name])}#{options} AS\n#{definition}"
      end
    end
  end
end
