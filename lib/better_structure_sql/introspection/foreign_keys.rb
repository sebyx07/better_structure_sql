# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    module ForeignKeys
      def fetch_foreign_keys(connection)
        adapter = get_adapter(connection)
        adapter.fetch_foreign_keys(connection)
      rescue StandardError => e
        warn "Warning: Failed to fetch foreign keys: #{e.message}"
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
