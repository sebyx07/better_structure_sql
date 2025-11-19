# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # SQLite-specific configuration settings
    class SqliteConfig
      attr_accessor :include_triggers, :include_views, :foreign_keys_enabled, :strict_mode

      def initialize
        @include_triggers = true
        @include_views = true
        @foreign_keys_enabled = true # PRAGMA foreign_keys=ON
        @strict_mode = false # Use STRICT tables in SQLite 3.37+
      end
    end
  end
end
