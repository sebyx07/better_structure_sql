# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module BetterStructureSql
  module Generators
    # Rails generator for creating schema_versions table migration
    class MigrationGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      desc 'Creates migration for BetterStructureSql schema versions table'

      # Creates migration file for schema_versions table
      #
      # @return [void]
      def create_migration_file
        migration_template(
          'migration.rb.erb',
          'db/migrate/create_better_structure_sql_schema_versions.rb',
          migration_version: migration_version
        )
      end

      private

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end
    end
  end
end
