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
        adapter_for(connection).fetch_extensions(connection)
      end
    end
  end
end
