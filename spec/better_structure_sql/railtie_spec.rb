# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'
require 'better_structure_sql/railtie'

RSpec.describe BetterStructureSql::Railtie do
  # Stands in for ActiveRecord::Tasks::DatabaseTasks without patching the real singleton
  let(:rails_tasks) do
    Module.new do
      def calls
        @calls ||= []
      end

      def schema_dump_path(db_config, format = nil)
        return ENV['SCHEMA'] if ENV['SCHEMA']

        "db/#{db_config.name}_#{format == :sql ? 'structure.sql' : 'schema.rb'}"
      end

      def dump_schema(db_config, format = nil)
        calls << [:rails_dump, db_config.name, format]
      end

      def with_temporary_connection(db_config)
        calls << [:connect, db_config.name]
        yield ActiveRecord::Base.connection
      end
    end
  end
  let(:tasks) do
    [
      rails_tasks,
      described_class::DatabaseTasksPathExtension,
      described_class::DatabaseTasksExtension,
      described_class::DatabaseTasksLoadExtension
    ].each_with_object(Object.new) { |extension, object| object.extend(extension) }
  end
  let(:temp_dir) { Pathname.new(Dir.mktmpdir) }
  let(:primary)  { db_config('primary', primary: true) }
  let(:animals)  { db_config('animals', primary: false) }

  def db_config(name, primary:, schema_dump: 'structure.sql', schema_format: :sql)
    double("#{name} db config", name:, primary?: primary, schema_dump:, schema_format:)
  end

  around do |example|
    original = BetterStructureSql.configuration
    BetterStructureSql.configuration = BetterStructureSql::Configuration.new.tap do |c|
      c.output_path = temp_dir.join('primary_schema')
    end
    example.run
  ensure
    BetterStructureSql.configuration = original
    FileUtils.rm_rf(temp_dir)
  end

  describe 'schema_dump_path' do
    it 'uses the configured output path for the primary database' do
      expect(tasks.schema_dump_path(primary, :sql)).to eq(temp_dir.join('primary_schema'))
    end

    it "falls back to the database's own schema format" do
      expect(tasks.schema_dump_path(primary)).to eq(temp_dir.join('primary_schema'))
    end

    it 'keeps a separate Rails path for secondary databases' do
      expect(tasks.schema_dump_path(animals, :sql)).to eq('db/animals_structure.sql')
    end

    it 'leaves the ruby format alone' do
      expect(tasks.schema_dump_path(primary, :ruby)).to eq('db/primary_schema.rb')
    end

    it 'respects schema_dump: false' do
      expect(tasks.schema_dump_path(db_config('primary', primary: true, schema_dump: nil), :sql))
        .to eq('db/primary_structure.sql')
    end

    it 'respects the SCHEMA environment variable' do
      ENV['SCHEMA'] = 'db/custom.sql'

      expect(tasks.schema_dump_path(primary, :sql)).to eq('db/custom.sql')
    ensure
      ENV.delete('SCHEMA')
    end
  end

  describe 'dump_schema' do
    let(:secondary_path) { temp_dir.join('animals_structure.sql') }

    before do
      path = secondary_path.to_s
      rails_tasks.define_method(:schema_dump_path) { |_db_config, _format = nil| path }
    end

    it 'dumps each database through its own connection into its own path' do
      tasks.dump_schema(primary, :sql)
      tasks.dump_schema(animals, :sql)

      expect(tasks.calls).to eq([[:connect, 'primary'], [:connect, 'animals']])
      expect(temp_dir.join('primary_schema', '_header.sql')).to exist
      expect(secondary_path.read).to include('CREATE TABLE')
    end

    it 'does not change the global configuration' do
      tasks.dump_schema(animals, :sql)

      expect(BetterStructureSql.configuration.output_path).to eq(temp_dir.join('primary_schema').to_s)
    end

    it 'uses the SQL dumper when sql is only the default format of the database' do
      tasks.dump_schema(animals)

      expect(secondary_path).to exist
    end

    it 'delegates the ruby format to Rails' do
      tasks.dump_schema(primary, :ruby)

      expect(tasks.calls).to eq([[:rails_dump, 'primary', :ruby]])
    end
  end

  describe 'structure_load' do
    it 'loads the file Rails resolved for the database being loaded' do
      loader = instance_double(BetterStructureSql::SchemaLoader, load: nil)
      allow(BetterStructureSql::SchemaLoader).to receive(:new).and_return(loader)

      tasks.structure_load(animals, 'db/animals_structure.sql')

      expect(loader).to have_received(:load).with('db/animals_structure.sql')
    end
  end
end
