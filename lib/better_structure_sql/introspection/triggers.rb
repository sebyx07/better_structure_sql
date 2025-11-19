# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    module Triggers
      def fetch_triggers(connection)
        adapter = get_adapter(connection)
        adapter.fetch_triggers(connection)
      rescue StandardError => e
        warn "Warning: Failed to fetch triggers: #{e.message}"
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
