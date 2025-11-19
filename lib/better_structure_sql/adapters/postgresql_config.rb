# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # PostgreSQL-specific configuration settings.
    # These settings are specific to PostgreSQL features and capabilities.
    class PostgresqlConfig
      # PostgreSQL-specific feature toggles can be added here
      # For now, we're using the main Configuration class feature toggles
      # In the future, we might add PostgreSQL-specific options like:
      # - pg_dump_compatibility_mode
      # - use_pg_catalog_vs_information_schema
      # - minimum_version_check

      def initialize
        # Future PostgreSQL-specific settings will be initialized here
      end
    end
  end
end
