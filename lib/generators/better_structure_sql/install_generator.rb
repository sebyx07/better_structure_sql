require "rails/generators/base"

module BetterStructureSql
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates BetterStructureSql initializer and instructions"

      def copy_initializer
        template "better_structure_sql.rb", "config/initializers/better_structure_sql.rb"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
