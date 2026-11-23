# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    # Introspection module for custom database types
    module Types
      # Fetches custom database types (enums, domains, composite)
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of type metadata hashes
      def fetch_custom_types(connection)
        adapter_for(connection).fetch_custom_types(connection)
      end

      # Fetches enum types only
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of enum type metadata hashes
      def fetch_enums(connection)
        fetch_custom_types(connection).select { |t| t[:type] == 'enum' }
      end
    end
  end
end
