# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    # Introspection module for database triggers
    module Triggers
      # Fetches database triggers
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of trigger metadata hashes
      def fetch_triggers(connection)
        adapter_for(connection).fetch_triggers(connection)
      end
    end
  end
end
