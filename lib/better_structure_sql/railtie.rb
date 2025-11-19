# frozen_string_literal: true

require 'rails/railtie'

module BetterStructureSql
  class Railtie < Rails::Railtie
    railtie_name :better_structure_sql

    rake_tasks do
      load 'tasks/better_structure_sql.rake'
    end

    initializer 'better_structure_sql.load_config' do
      config_file = Rails.root.join('config/initializers/better_structure_sql.rb')
      load config_file if config_file.exist?
    end

    initializer 'better_structure_sql.replace_default_dump', after: 'active_record.set_configs' do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(DatabaseTasksExtension) if BetterStructureSql.configuration.replace_default_dump
      end
    end

    module DatabaseTasksExtension
      def structure_dump(_configuration, *_args)
        BetterStructureSql::Dumper.new.dump
      end
    end
  end
end
