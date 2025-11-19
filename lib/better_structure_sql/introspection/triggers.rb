# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    # Introspection module for database triggers
    module Triggers
      # Fetches database triggers
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of trigger metadata hashes
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
