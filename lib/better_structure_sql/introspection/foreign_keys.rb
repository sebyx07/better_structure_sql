# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    # Introspection module for foreign key constraints
    module ForeignKeys
      # Fetches foreign key constraints
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of foreign key metadata hashes
      def fetch_foreign_keys(connection)
        adapter_for(connection).fetch_foreign_keys(connection)
      end
    end
  end
end
