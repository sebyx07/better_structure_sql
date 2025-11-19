require "active_record"
require_relative "better_structure_sql/version"
require_relative "better_structure_sql/configuration"
require_relative "better_structure_sql/introspection"
require_relative "better_structure_sql/formatter"
require_relative "better_structure_sql/generators/base"
require_relative "better_structure_sql/generators/extension_generator"
require_relative "better_structure_sql/generators/type_generator"
require_relative "better_structure_sql/generators/sequence_generator"
require_relative "better_structure_sql/generators/table_generator"
require_relative "better_structure_sql/generators/index_generator"
require_relative "better_structure_sql/generators/foreign_key_generator"
require_relative "better_structure_sql/dumper"
require_relative "better_structure_sql/railtie" if defined?(Rails::Railtie)

module BetterStructureSql
  class Error < StandardError; end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration
      @configuration = Configuration.new
    end
  end
end
