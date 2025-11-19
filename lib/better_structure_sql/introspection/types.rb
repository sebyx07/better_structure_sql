# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    module Types
      def fetch_custom_types(connection)
        adapter = get_adapter(connection)
        adapter.fetch_custom_types(connection)
      rescue StandardError => e
        warn "Warning: Failed to fetch custom types: #{e.message}"
        []
      end

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
