# frozen_string_literal: true

module BetterStructureSql
  # Deprecated: Use DatabaseVersion instead.
  # This module is kept for backward compatibility.
  module PgVersion
    # rubocop:disable Rails/Delegate
    # delegate doesn't work for delegating to module constants
    class << self
      def detect(connection = ActiveRecord::Base.connection)
        DatabaseVersion.detect(connection)
      end

      def parse_version(version_string)
        DatabaseVersion.parse_version(version_string)
      end

      def major_version(version_string)
        DatabaseVersion.major_version(version_string)
      end

      def minor_version(version_string)
        DatabaseVersion.minor_version(version_string)
      end
    end
    # rubocop:enable Rails/Delegate
  end
end
