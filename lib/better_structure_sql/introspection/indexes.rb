# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    module Indexes
      def fetch_indexes(connection)
        adapter = get_adapter(connection)
        adapter.fetch_indexes(connection)
      rescue StandardError => e
        warn "Warning: Failed to fetch indexes: #{e.message}"
        []
      end

      private

      def get_adapter(connection)
        @get_adapter ||= Adapters::Registry.adapter_for(
          connection,
          adapter_override: BetterStructureSql.configuration.adapter
        )
      end
    end
  end
end
