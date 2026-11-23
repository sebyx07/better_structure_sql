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
        adapter_for(connection).fetch_indexes(connection)
      end
    end
  end
end
