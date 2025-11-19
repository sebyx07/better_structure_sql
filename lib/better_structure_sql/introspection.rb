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
  # all supported adapters (PostgreSQL, MySQL, SQLite).
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
    end
  end
end
