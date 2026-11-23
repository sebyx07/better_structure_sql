# frozen_string_literal: true

require 'rails_helper'
require 'rake'
require 'tmpdir'

RSpec.describe 'better_structure_sql rake tasks' do
  let(:connection) { ActiveRecord::Base.connection }
  let(:temp_dir)   { Pathname.new(Dir.mktmpdir) }
  let(:config)     { BetterStructureSql.configuration }

  around do |example|
    original_rake = Rake.application
    original_config = BetterStructureSql.configuration
    Rake.application = Rake::Application.new
    BetterStructureSql.configuration = BetterStructureSql::Configuration.new
    Rake::Task.define_task(:environment)
    Rake::Task.define_task('db:load_config')
    Rake::Task.define_task('db:check_protected_environments')
    load File.expand_path('../../lib/tasks/better_structure_sql.rake', __dir__)
    example.run
  ensure
    Rake.application = original_rake
    BetterStructureSql.configuration = original_config
    FileUtils.rm_rf(temp_dir)
  end

  before do
    allow(Rails).to receive(:root).and_return(temp_dir)
    config.output_path = 'db/structure.sql'
    config.enable_schema_versions = true
  end

  def store_version(content, **attributes)
    BetterStructureSql::SchemaVersions.store(
      content:, content_hash: Digest::MD5.hexdigest(content), format_type: 'sql', pg_version: '17.0', **attributes
    )
  end

  describe 'db:schema:store' do
    it 'fails loudly when there is no schema to store' do
      expect { Rake::Task['db:schema:store'].invoke }
        .to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
        .and output(%r{No schema found at db/structure.sql}).to_stderr
      expect(BetterStructureSql::SchemaVersion.count).to eq(0)
    end

    it 'stores the dumped schema' do
      FileUtils.mkdir_p(temp_dir.join('db'))
      File.write(temp_dir.join('db/structure.sql'), '-- schema')

      expect { Rake::Task['db:schema:store'].invoke }.to output(/Stored schema version #\d+/).to_stdout
    end

    it 'keeps the checked-in multi-file schema directory' do
      config.output_path = 'db/schema'
      FileUtils.mkdir_p(temp_dir.join('db/schema/05_tables'))
      File.write(temp_dir.join('db/schema/05_tables/000001.sql'), 'CREATE TABLE users (id bigint);')

      expect { Rake::Task['db:schema:store'].invoke }.to output(/Mode: multi_file/).to_stdout

      expect(temp_dir.join('db/schema/05_tables/000001.sql').read).to eq('CREATE TABLE users (id bigint);')
    end
  end

  describe 'db:schema:load_better' do
    before do
      FileUtils.mkdir_p(temp_dir.join('db'))
      File.write(temp_dir.join('db/structure.sql'), 'CREATE TABLE bss_loaded_better (id bigint);')
    end

    after do
      connection.drop_table(:bss_loaded_better, if_exists: true)
      connection.drop_table(:ar_internal_metadata, if_exists: true)
    end

    def internal_metadata(key)
      connection.select_value("SELECT value FROM ar_internal_metadata WHERE key = #{connection.quote(key)}")
    end

    it 'loads the schema and records the environment and schema checksum like the Rails schema load' do
      Rake::Task['db:schema:load_better'].invoke

      expect(connection.table_exists?(:bss_loaded_better)).to be true
      expect(internal_metadata('environment')).to eq('test')
      expect(internal_metadata('schema_sha1')).to eq(Digest::SHA1.hexdigest('CREATE TABLE bss_loaded_better (id bigint);'))
    end
  end

  describe 'db:schema:restore' do
    before { allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:purge) }

    it 'refuses to replace the database schema without CONFIRM=1' do
      version = store_version('CREATE TABLE bss_restored_single (id bigint);')

      expect { Rake::Task['db:schema:restore'].invoke(version.id) }
        .to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
        .and output(/drops every table and all data.*CONFIRM=1/m).to_stderr
      expect(ActiveRecord::Tasks::DatabaseTasks).not_to have_received(:purge)
      expect(connection.table_exists?('bss_restored_single')).to be false
    end

    it 'runs the Rails protected environment check first' do
      expect(Rake::Task['db:schema:restore'].prerequisites).to eq(%w[environment check_protected_environments])
    end

    it 'fails for an unknown version before touching the database' do
      stub_const('ENV', ENV.to_h.merge('CONFIRM' => '1'))

      expect { Rake::Task['db:schema:restore'].invoke(0) }.to raise_error(RuntimeError, 'Version 0 not found')
      expect(ActiveRecord::Tasks::DatabaseTasks).not_to have_received(:purge)
    end
  end

  describe 'db:schema:cleanup' do
    it 'does not terminate the rake run when retention is unlimited' do
      config.schema_versions_limit = 0

      expect { Rake::Task['db:schema:cleanup'].invoke }.to output(/unlimited/).to_stdout
    end
  end
end
