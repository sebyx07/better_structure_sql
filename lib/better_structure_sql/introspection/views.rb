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
        adapter_for(connection).fetch_views(connection)
      end

      # Fetches materialized views
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of materialized view metadata hashes
      def fetch_materialized_views(connection)
        adapter_for(connection).fetch_materialized_views(connection)
      end
    end
  end
end
