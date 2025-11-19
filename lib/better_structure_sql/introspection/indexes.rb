# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    # Introspection module for database indexes
    module Indexes
      # Fetches database indexes
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of index metadata hashes
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
