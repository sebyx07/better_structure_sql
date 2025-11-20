# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # Base adapter class defining the interface contract for database-specific adapters.
    #
    # All concrete adapters must inherit from this class and implement the abstract methods.
    # This class provides the foundation for database introspection and SQL generation across
    # different database systems (PostgreSQL, MySQL, SQLite).
    #
    # @abstract Subclasses must implement all abstract methods
    class BaseAdapter
      # @return [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      attr_reader :connection

      # Initialize a new adapter instance
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      def initialize(connection)
        @connection = connection
      end

      # Abstract introspection methods - must be implemented by subclasses

      # Fetch database extensions
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of extension hashes with :name, :version, :schema
      # @raise [NotImplementedError] If not implemented by subclass
      def fetch_extensions(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_extensions"
      end

      # Fetch custom types (enums, composite types, domains)
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of type hashes with :name, :type, :schema, and type-specific attributes
      # @raise [NotImplementedError] If not implemented by subclass
      def fetch_custom_types(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_custom_types"
      end

      # Fetch tables with columns and constraints
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of table hashes with :name, :schema, :columns, :primary_key, :constraints
      # @raise [NotImplementedError] If not implemented by subclass
      def fetch_tables(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_tables"
      end

      # Fetch indexes
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of index hashes with :name, :table, :columns, :unique, :type
      # @raise [NotImplementedError] If not implemented by subclass
      def fetch_indexes(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_indexes"
      end

      # Fetch foreign keys
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of foreign key hashes with :table, :name, :column, :foreign_table, :foreign_column, :on_update, :on_delete
      # @raise [NotImplementedError] If not implemented by subclass
      def fetch_foreign_keys(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_foreign_keys"
      end

      # Fetch views
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of view hashes with :schema, :name, :definition
      # @raise [NotImplementedError] If not implemented by subclass
      def fetch_views(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_views"
      end

      # Fetch materialized views
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of materialized view hashes with :schema, :name, :definition, :indexes
      # @raise [NotImplementedError] If not implemented by subclass
      def fetch_materialized_views(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_materialized_views"
      end

      # Fetch functions
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of function hashes with :schema, :name, :definition
      # @raise [NotImplementedError] If not implemented by subclass
      def fetch_functions(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_functions"
      end

      # Fetch sequences
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of sequence hashes with :name, :schema, :start_value, :increment
      # @raise [NotImplementedError] If not implemented by subclass
      def fetch_sequences(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_sequences"
      end

      # Fetch triggers
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of trigger hashes with :schema, :name, :table_name, :definition
      # @raise [NotImplementedError] If not implemented by subclass
      def fetch_triggers(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_triggers"
      end

      # Fetch comments on database objects
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Hash] Hash with object types as keys (:tables, :columns, :indexes, etc.)
      #   Each value is a hash mapping object identifier to comment text
      #   Example: { tables: { 'users' => 'User accounts', ... }, columns: { 'users.email' => 'Email address', ... } }
      # @raise [NotImplementedError] If not implemented by subclass
      def fetch_comments(connection)
        raise NotImplementedError, "#{self.class} must implement #fetch_comments"
      end

      # Capability methods - indicate feature support

      # Indicates whether this database supports extensions (like PostgreSQL extensions)
      #
      # @return [Boolean] True if extensions are supported, false otherwise
      def supports_extensions?
        false
      end

      # Indicates whether this database supports materialized views
      #
      # @return [Boolean] True if materialized views are supported, false otherwise
      def supports_materialized_views?
        false
      end

      # Indicates whether this database supports custom types (enums, composite types)
      #
      # @return [Boolean] True if custom types are supported, false otherwise
      def supports_custom_types?
        false
      end

      # Indicates whether this database supports domains
      #
      # @return [Boolean] True if domains are supported, false otherwise
      def supports_domains?
        false
      end

      # Indicates whether this database supports stored procedures/functions
      #
      # @return [Boolean] True if functions are supported, false otherwise
      def supports_functions?
        false
      end

      # Indicates whether this database supports triggers
      #
      # @return [Boolean] True if triggers are supported, false otherwise
      def supports_triggers?
        false
      end

      # Indicates whether this database supports sequences
      #
      # @return [Boolean] True if sequences are supported, false otherwise
      def supports_sequences?
        false
      end

      # Indicates whether this database supports comments on database objects
      #
      # @return [Boolean] True if comments are supported, false otherwise
      def supports_comments?
        false
      end

      # Version detection

      # Detect the database version
      #
      # @return [String] Normalized version string (e.g., "14.5" for PostgreSQL 14.5)
      # @raise [NotImplementedError] If not implemented by subclass
      def database_version
        raise NotImplementedError, "#{self.class} must implement #database_version"
      end

      # Parse version string from database
      #
      # @param version_string [String] Raw version string from database
      # @return [String] Normalized version (e.g., "14.5")
      # @raise [NotImplementedError] If not implemented by subclass
      def parse_version(version_string)
        raise NotImplementedError, "#{self.class} must implement #parse_version"
      end

      # Utility methods for version comparison

      # Extract major version number
      #
      # @param version_string [String] Version string (e.g., "14.5")
      # @return [Integer] Major version (e.g., 14)
      def major_version(version_string)
        version_string.split('.').first.to_i
      end

      # Extract minor version number
      #
      # @param version_string [String] Version string (e.g., "14.5")
      # @return [Integer] Minor version (e.g., 5), or 0 if not present
      def minor_version(version_string)
        parts = version_string.split('.')
        parts.length > 1 ? parts[1].to_i : 0
      end

      # Compare two version strings
      #
      # @param version1 [String] First version to compare
      # @param version2 [String] Second version to compare
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
      #
      # @param current_version [String] Current database version
      # @param required_version [String] Required minimum version
      # @return [Boolean] True if current version is greater than or equal to required version
      def version_at_least?(current_version, required_version)
        compare_versions(current_version, required_version) >= 0
      end
    end
  end
end
