# frozen_string_literal: true

module BetterStructureSql
  # Deprecated: Use DatabaseVersion instead.
  # This module is kept for backward compatibility.
  module PgVersion
    class << self
      def detect(connection = ActiveRecord::Base.connection)
        DatabaseVersion.detect(connection)
      end

      delegate :parse_version, to: :DatabaseVersion

      delegate :major_version, to: :DatabaseVersion

      delegate :minor_version, to: :DatabaseVersion
    end
  end
end
