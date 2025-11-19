# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    # Introspection module for database extensions
    module Extensions
      # Fetches database extensions
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of extension metadata hashes
      def fetch_extensions(connection)
        adapter = get_adapter(connection)
        adapter.fetch_extensions(connection)
      rescue StandardError => e
        warn "Warning: Failed to fetch extensions: #{e.message}"
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
