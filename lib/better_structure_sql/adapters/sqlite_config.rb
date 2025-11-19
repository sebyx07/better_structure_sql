# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # SQLite-specific configuration settings
    #
    # Provides configuration options specific to SQLite database adapter.
    # These settings control which SQLite features are included in schema dumps
    # and database behavior.
    class SqliteConfig
      # @return [Boolean] Whether to include triggers in schema dump
      # @return [Boolean] Whether to include views in schema dump
      # @return [Boolean] Whether to enable foreign key constraints (PRAGMA foreign_keys=ON)
      # @return [Boolean] Whether to use STRICT tables in SQLite 3.37+
      attr_accessor :include_triggers, :include_views, :foreign_keys_enabled, :strict_mode

      # Initialize SQLite configuration with default values
      def initialize
        @include_triggers = true
        @include_views = true
        @foreign_keys_enabled = true # PRAGMA foreign_keys=ON
        @strict_mode = false # Use STRICT tables in SQLite 3.37+
      end
    end
  end
end
