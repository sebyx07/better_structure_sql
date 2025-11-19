# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # PostgreSQL-specific configuration settings
    #
    # Provides configuration options specific to PostgreSQL database adapter.
    # Currently uses the main Configuration class feature toggles.
    # Future PostgreSQL-specific options may include pg_dump_compatibility_mode,
    # use_pg_catalog_vs_information_schema, and minimum_version_check.
    class PostgresqlConfig
      # PostgreSQL-specific feature toggles can be added here
      # For now, we're using the main Configuration class feature toggles
      # In the future, we might add PostgreSQL-specific options like:
      # - pg_dump_compatibility_mode
      # - use_pg_catalog_vs_information_schema
      # - minimum_version_check

      # Initialize PostgreSQL configuration with default values
      def initialize
        # Future PostgreSQL-specific settings will be initialized here
      end
    end
  end
end
