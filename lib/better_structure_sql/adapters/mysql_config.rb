# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # MySQL-specific configuration settings
    class MysqlConfig
      attr_accessor :include_stored_procedures, :include_triggers, :include_views, :use_show_create, :charset, :collation, :min_version

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
