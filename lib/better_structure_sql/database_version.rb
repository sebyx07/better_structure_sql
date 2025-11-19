# frozen_string_literal: true

module BetterStructureSql
  # Database version detection abstraction.
  # Delegates to the appropriate adapter for version detection.
  module DatabaseVersion
    class << self
      def detect(connection = ActiveRecord::Base.connection)
        adapter = Adapters::Registry.adapter_for(
          connection,
          adapter_override: BetterStructureSql.configuration.adapter
        )
        adapter.database_version
      end

      # For backward compatibility with PgVersion
      def parse_version(version_string)
        # This is kept for backward compatibility but now delegates to adapter
        connection = ActiveRecord::Base.connection
        adapter = Adapters::Registry.adapter_for(
          connection,
          adapter_override: BetterStructureSql.configuration.adapter
        )
        adapter.parse_version(version_string)
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
