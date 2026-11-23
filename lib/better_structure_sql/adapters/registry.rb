# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # Registry for database adapters using factory pattern.
    # Handles adapter detection from ActiveRecord connection and caching.
    class Registry
      class << self
        # Get adapter for a connection (with caching)
        # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
        # @param adapter_override [Symbol, nil] Manual adapter override (:postgresql, :mysql, :sqlite, :auto)
        # @return [BaseAdapter] Adapter instance
        def adapter_for(connection, adapter_override: :auto)
          # Use cache key based on connection object_id and adapter override
          cache_key = "#{connection.object_id}_#{adapter_override}"

          @adapter_cache ||= {}
          @adapter_cache[cache_key] ||= create_adapter(connection, adapter_override)
        end

        # Clear adapter cache (useful for testing)
        def clear_cache!
          @adapter_cache = {}
        end

        private

        # Create new adapter instance
        # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
        # @param adapter_override [Symbol] Adapter type
        # @return [BaseAdapter] Adapter instance
        def create_adapter(connection, adapter_override)
          adapter_name = resolve_adapter_name(connection, adapter_override)

          case adapter_name
          when :postgresql
            require_relative 'postgresql_adapter'
            PostgresqlAdapter.new(connection)
          when :mysql
            require_relative 'mysql_adapter'
            require_driver!(mysql_driver_gem(connection), 'MySQL')
            MysqlAdapter.new(connection)
          when :sqlite
            require_relative 'sqlite_adapter'
            require_driver!('sqlite3', 'SQLite')
            SqliteAdapter.new(connection)
          else
            raise Error, "Unknown database adapter: #{adapter_name}"
          end
        end

        # Resolve adapter name from connection or override
        # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
        # @param adapter_override [Symbol] Manual override or :auto
        # @return [Symbol] Adapter name (:postgresql, :mysql, :sqlite)
        def resolve_adapter_name(connection, adapter_override)
          if adapter_override != :auto
            validate_adapter_override!(adapter_override)
            return adapter_override
          end

          # Auto-detect from ActiveRecord connection
          detect_adapter_from_connection(connection)
        end

        # Detect adapter from ActiveRecord connection
        # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
        # @return [Symbol] Adapter name
        def detect_adapter_from_connection(connection)
          adapter_name = connection.adapter_name.downcase

          case adapter_name
          when 'postgresql', 'postgis'
            :postgresql
          when 'mysql2', 'mysql', 'trilogy'
            :mysql
          when 'sqlite3', 'sqlite'
            :sqlite
          else
            raise Error, "Unsupported database adapter: #{adapter_name}. " \
                         'Supported: postgresql, postgis, mysql2, trilogy, sqlite3'
          end
        end

        # Validate manual adapter override
        # @param adapter_override [Symbol]
        # @raise [Error] If adapter override is invalid
        def validate_adapter_override!(adapter_override)
          valid_adapters = %i[postgresql mysql sqlite auto]

          return if valid_adapters.include?(adapter_override)

          raise Error, "Invalid adapter override: #{adapter_override}. " \
                       "Valid options: #{valid_adapters.join(', ')}"
        end

        # Driver gem backing a MySQL connection: trilogy (the Rails 7.1+
        # default) or mysql2
        # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
        # @return [String] Gem name
        def mysql_driver_gem(connection)
          connection.adapter_name.casecmp?('trilogy') ? 'trilogy' : 'mysql2'
        end

        # Require a database driver gem, failing with installation instructions
        # @param gem_name [String] Driver gem (mysql2, trilogy, sqlite3)
        # @param database [String] Human-readable database name
        # @raise [Error] If the gem is not installed
        def require_driver!(gem_name, database)
          require gem_name
        rescue LoadError => e
          raise Error, "#{database} support requires the #{gem_name} gem (#{e.message}). " \
                       "Add to your Gemfile: gem \"#{gem_name}\""
        end
      end
    end
  end
end
