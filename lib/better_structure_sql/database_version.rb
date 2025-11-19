# frozen_string_literal: true

module BetterStructureSql
  # Database version detection abstraction.
  # Delegates to the appropriate adapter for version detection.
  module DatabaseVersion
    class << self
      # Detects database version using the appropriate adapter
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [String] Database version string
      def detect(connection = ActiveRecord::Base.connection)
        adapter = Adapters::Registry.adapter_for(
          connection,
          adapter_override: BetterStructureSql.configuration.adapter
        )
        adapter.database_version
      end

      # For backward compatibility with PgVersion
      def parse_version(version_string)
        # Parse version string directly (PostgreSQL format)
        # Example: "PostgreSQL 15.1 on x86_64" → "15.1"
        match = version_string.match(/(\d+\.\d+(\.\d+)?)/)
        match ? match[1] : 'unknown'
      end

      # Extracts major version number from version string
      #
      # @param version_string [String] Version string (e.g., "15.1.0")
      # @return [Integer] Major version number
      def major_version(version_string)
        version_string.split('.').first.to_i
      end

      # Extracts minor version number from version string
      #
      # @param version_string [String] Version string (e.g., "15.1.0")
      # @return [Integer] Minor version number
      def minor_version(version_string)
        parts = version_string.split('.')
        parts.length > 1 ? parts[1].to_i : 0
      end
    end
  end
end
