require "rails/generators/base"

module BetterStructureSql
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates BetterStructureSql initializer and optionally generates migration"

      class_option :skip_migration,
                   type: :boolean,
                   default: false,
                   desc: "Skip migration generation for schema versions table"

      def copy_initializer
        template "better_structure_sql.rb", "config/initializers/better_structure_sql.rb"
      end

      def create_migration
        return if options[:skip_migration]

        generate "better_structure_sql:migration"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
