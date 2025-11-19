# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # Base adapter class defining the interface contract for database-specific adapters.
    # All concrete adapters must inherit from this class and implement the abstract methods.
    class BaseAdapter
      attr_reader :connection

      def initialize(connection)
        @connection = connection
      end

      # Abstract introspection methods - must be implemented by subclasses

      # Fetch database extensions
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
      # @return [Array<Hash>] Array of extension hashes with :name, :version, :schema
      def fetch_extensions(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_extensions"
      end

      # Fetch custom types (enums, composite types, domains)
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
      # @return [Array<Hash>] Array of type hashes
      def fetch_custom_types(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_custom_types"
      end

      # Fetch tables with columns and constraints
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
      # @return [Array<Hash>] Array of table hashes
      def fetch_tables(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_tables"
      end

      # Fetch indexes
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
      # @return [Array<Hash>] Array of index hashes
      def fetch_indexes(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_indexes"
      end

      # Fetch foreign keys
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
      # @return [Array<Hash>] Array of foreign key hashes
      def fetch_foreign_keys(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_foreign_keys"
      end

      # Fetch views
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
      # @return [Array<Hash>] Array of view hashes
      def fetch_views(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_views"
      end

      # Fetch materialized views
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
      # @return [Array<Hash>] Array of materialized view hashes
      def fetch_materialized_views(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_materialized_views"
      end

      # Fetch functions
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
      # @return [Array<Hash>] Array of function hashes
      def fetch_functions(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_functions"
      end

      # Fetch sequences
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
      # @return [Array<Hash>] Array of sequence hashes
      def fetch_sequences(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_sequences"
      end

      # Fetch triggers
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
      # @return [Array<Hash>] Array of trigger hashes
      def fetch_triggers(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_triggers"
      end

      # Capability methods - indicate feature support

      # Does this database support extensions (like PostgreSQL extensions)?
      # @return [Boolean]
      def supports_extensions?
        false
      end

      # Does this database support materialized views?
      # @return [Boolean]
      def supports_materialized_views?
        false
      end

      # Does this database support custom types (enums, composite types)?
      # @return [Boolean]
      def supports_custom_types?
        false
      end

      # Does this database support domains?
      # @return [Boolean]
      def supports_domains?
        false
      end

      # Does this database support stored procedures/functions?
      # @return [Boolean]
      def supports_functions?
        false
      end

      # Does this database support triggers?
      # @return [Boolean]
      def supports_triggers?
        false
      end

      # Does this database support sequences?
      # @return [Boolean]
      def supports_sequences?
        false
      end

      # Version detection

      # Detect the database version
      # @return [String] Version string (e.g., "14.5" for PostgreSQL 14.5)
      def database_version
        raise NotImplementedError, "#{self.class} must implement #database_version"
      end

      # Parse version string from database
      # @param version_string [String] Raw version string from database
      # @return [String] Normalized version (e.g., "14.5")
      def parse_version(version_string)
        raise NotImplementedError, "#{self.class} must implement #parse_version"
      end

      # Utility methods for version comparison

      # Extract major version number
      # @param version_string [String] Version string (e.g., "14.5")
      # @return [Integer] Major version (e.g., 14)
      def major_version(version_string)
        version_string.split('.').first.to_i
      end

      # Extract minor version number
      # @param version_string [String] Version string (e.g., "14.5")
      # @return [Integer] Minor version (e.g., 5)
      def minor_version(version_string)
        parts = version_string.split('.')
        parts.length > 1 ? parts[1].to_i : 0
      end

      # Compare two version strings
      # @param version1 [String] First version
      # @param version2 [String] Second version
      # @return [Integer] -1 if version1 < version2, 0 if equal, 1 if version1 > version2
      def compare_versions(version1, version2)
        v1_parts = version1.split('.').map(&:to_i)
        v2_parts = version2.split('.').map(&:to_i)

        [v1_parts.length, v2_parts.length].max.times do |i|
          v1 = v1_parts[i] || 0
          v2 = v2_parts[i] || 0

          return -1 if v1 < v2
          return 1 if v1 > v2
        end

        0
      end

      # Check if version meets minimum requirement
      # @param current_version [String] Current version
      # @param required_version [String] Required minimum version
      # @return [Boolean] True if current >= required
      def version_at_least?(current_version, required_version)
        compare_versions(current_version, required_version) >= 0
      end
    end
  end
end
