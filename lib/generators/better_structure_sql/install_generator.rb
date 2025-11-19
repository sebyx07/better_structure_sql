# frozen_string_literal: true

require 'rails/generators/base'

module BetterStructureSql
  module Generators
    # Rails generator for installing BetterStructureSql
    #
    # Creates initializer and optionally generates migration for schema_versions table.
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Creates BetterStructureSql initializer and optionally generates migration'

      class_option :skip_migration,
                   type: :boolean,
                   default: false,
                   desc: 'Skip migration generation for schema versions table'

      # Copies initializer template to config/initializers
      #
      # @return [void]
      def copy_initializer
        template 'better_structure_sql.rb', 'config/initializers/better_structure_sql.rb'
      end

      # Creates migration for schema_versions table
      #
      # @return [void]
      def create_migration
        return if options[:skip_migration]

        generate 'better_structure_sql:migration'
      end

      # Displays README after installation
      #
      # @return [void]
      def show_readme
        readme 'README' if behavior == :invoke
      end
    end
  end
end
