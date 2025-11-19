# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    # Introspection module for database functions
    module Functions
      # Fetches database functions and stored procedures
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of function metadata hashes
      def fetch_functions(connection)
        adapter = get_adapter(connection)
        adapter.fetch_functions(connection)
      rescue StandardError => e
        warn "Warning: Failed to fetch functions: #{e.message}"
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
