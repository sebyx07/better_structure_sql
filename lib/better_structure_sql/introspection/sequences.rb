# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    # Introspection module for database sequences
    module Sequences
      # Fetches database sequences
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of sequence metadata hashes
      def fetch_sequences(connection)
        adapter = get_adapter(connection)
        adapter.fetch_sequences(connection)
      rescue StandardError => e
        warn "Warning: Failed to fetch sequences: #{e.message}"
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
