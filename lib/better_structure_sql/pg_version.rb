# frozen_string_literal: true

module BetterStructureSql
  # Deprecated: Use DatabaseVersion instead.
  # This module is kept for backward compatibility.
  module PgVersion
    # rubocop:disable Rails/Delegate
    # delegate doesn't work for delegating to module constants
    class << self
      # Delegates to DatabaseVersion.detect
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [String] Database version
      def detect(connection = ActiveRecord::Base.connection)
        DatabaseVersion.detect(connection)
      end

      # Delegates to DatabaseVersion.parse_version
      #
      # @param version_string [String] Version string
      # @return [String] Parsed version
      def parse_version(version_string)
        DatabaseVersion.parse_version(version_string)
      end

      # Delegates to DatabaseVersion.major_version
      #
      # @param version_string [String] Version string
      # @return [Integer] Major version number
      def major_version(version_string)
        DatabaseVersion.major_version(version_string)
      end

      # Delegates to DatabaseVersion.minor_version
      #
      # @param version_string [String] Version string
      # @return [Integer] Minor version number
      def minor_version(version_string)
        DatabaseVersion.minor_version(version_string)
      end
    end
    # rubocop:enable Rails/Delegate
  end
end
