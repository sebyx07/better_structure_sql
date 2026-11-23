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
        adapter_for(connection).fetch_functions(connection)
      end
    end
  end
end
