# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # MySQL-specific configuration settings
    #
    # Provides configuration options specific to MySQL database adapter.
    # These settings control which MySQL features are included in schema dumps
    # and how they are generated.
    class MysqlConfig
      # @return [Boolean] Whether to include stored procedures in schema dump
      # @return [Boolean] Whether to include triggers in schema dump
      # @return [Boolean] Whether to include views in schema dump
      # @return [Boolean] Whether to use SHOW CREATE statements instead of information_schema
      # @return [String] Default character set for MySQL (default: 'utf8mb4')
      # @return [String] Default collation for MySQL (default: 'utf8mb4_unicode_ci')
      # @return [String] Minimum MySQL version required (default: '8.0')
      attr_accessor :include_stored_procedures, :include_triggers, :include_views, :use_show_create, :charset, :collation, :min_version

      # Initialize MySQL configuration with default values
      def initialize
        @include_stored_procedures = true
        @include_triggers = true
        @include_views = true
        @use_show_create = false # Use information_schema by default
        @charset = 'utf8mb4'
        @collation = 'utf8mb4_unicode_ci'
        @min_version = '8.0'
      end
    end
  end
end
