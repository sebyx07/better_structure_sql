# frozen_string_literal: true

module BetterStructureSql
  module PgVersion
    class << self
      def detect(connection = ActiveRecord::Base.connection)
        version_string = connection.select_value('SELECT version()')
        parse_version(version_string)
      end

      def parse_version(version_string)
        # Example: "PostgreSQL 14.5 (Ubuntu 14.5-1.pgdg20.04+1) on x86_64-pc-linux-gnu..."
        # Extract major.minor version
        match = version_string.match(/PostgreSQL (\d+\.\d+)/)
        return 'unknown' unless match

        match[1]
      end

      def major_version(version_string)
        version_string.split('.').first.to_i
      end

      def minor_version(version_string)
        parts = version_string.split('.')
        parts.length > 1 ? parts[1].to_i : 0
      end
    end
  end
end
