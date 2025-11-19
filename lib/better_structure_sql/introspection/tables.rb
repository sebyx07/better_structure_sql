# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    # Introspection module for database tables
    module Tables
      # Fetches database tables
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of table metadata hashes
      def fetch_tables(connection)
        adapter = get_adapter(connection)
        adapter.fetch_tables(connection)
      rescue StandardError => e
        warn "Warning: Failed to fetch tables: #{e.message}"
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
