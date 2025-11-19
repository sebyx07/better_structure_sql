# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    # Introspection module for database views
    module Views
      # Fetches database views
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of view metadata hashes
      def fetch_views(connection)
        adapter = get_adapter(connection)
        adapter.fetch_views(connection)
      rescue StandardError => e
        warn "Warning: Failed to fetch views: #{e.message}"
        []
      end

      # Fetches materialized views
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of materialized view metadata hashes
      def fetch_materialized_views(connection)
        adapter = get_adapter(connection)
        adapter.fetch_materialized_views(connection)
      rescue StandardError => e
        warn "Warning: Failed to fetch materialized views: #{e.message}"
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
