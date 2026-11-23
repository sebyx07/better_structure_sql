# frozen_string_literal: true

require_relative 'introspection/extensions'
require_relative 'introspection/sequences'
require_relative 'introspection/types'
require_relative 'introspection/tables'
require_relative 'introspection/indexes'
require_relative 'introspection/foreign_keys'
require_relative 'introspection/views'
require_relative 'introspection/functions'
require_relative 'introspection/triggers'

module BetterStructureSql
  # Introspection facade for database metadata extraction
  #
  # Provides a unified interface for querying database objects across
  # all supported adapters (PostgreSQL, MySQL, SQLite). Introspection errors
  # propagate: a dump silently missing objects is worse than a failed dump.
  module Introspection
    class << self
      include Extensions
      include Sequences
      include Types
      include Tables
      include Indexes
      include ForeignKeys
      include Views
      include Functions
      include Triggers

      private

      # Adapter for the given connection (cached per connection by the Registry)
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Adapters::BaseAdapter] Adapter instance
      def adapter_for(connection)
        Adapters::Registry.adapter_for(connection, adapter_override: BetterStructureSql.configuration.adapter)
      end
    end
  end
end
