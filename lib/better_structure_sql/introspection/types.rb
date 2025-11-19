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
        adapter = get_adapter(connection)
        adapter.fetch_custom_types(connection)
      rescue StandardError => e
        warn "Warning: Failed to fetch custom types: #{e.message}"
        []
      end

      # Fetches enum types only
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of enum type metadata hashes
      def fetch_enums(connection)
        fetch_custom_types(connection).select { |t| t[:type] == 'enum' }
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
