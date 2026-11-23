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
        adapter_for(connection).fetch_sequences(connection)
      end
    end
  end
end
