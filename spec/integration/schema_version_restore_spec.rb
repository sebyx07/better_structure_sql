# frozen_string_literal: true

require 'rails_helper'
require 'rake'
require 'tmpdir'

# db:schema:restore replaces the schema of the database the version was read from,
# so it runs against a database of its own: the task purges it.
RSpec.describe 'db:schema:restore into the database that stores the version' do
  let(:temp_dir)   { Pathname.new(Dir.mktmpdir) }
  let(:config)     { BetterStructureSql.configuration }

  before(:all) do
    # The in-memory SQLite suite database would not survive the purge and reconnect
    skip 'requires a PostgreSQL DATABASE_URL' unless ActiveRecord::Base.connection.adapter_name.match?(/postg/i)
  end

  around do |example|
    original_db_config = ActiveRecord::Base.connection_db_config
    original_rake = Rake.application
    original_config = BetterStructureSql.configuration
    restore_db_config = restore_database_config(original_db_config)
    ActiveRecord::Tasks::DatabaseTasks.purge(restore_db_config)
    ActiveRecord::Base.establish_connection(restore_db_config)
    BetterStructureSql.configuration = BetterStructureSql::Configuration.new
    load_rake_tasks
    example.run
  ensure
    Rake.application = original_rake
    BetterStructureSql.configuration = original_config
    ActiveRecord::Base.establish_connection(original_db_config)
    connection.drop_database(restore_db_config.database)
    BetterStructureSql::Adapters::Registry.clear_cache!
    FileUtils.rm_rf(temp_dir)
  end

  before do
    allow(Rails).to receive(:root).and_return(temp_dir)
    stub_const('ENV', ENV.to_h.merge('CONFIRM' => '1'))
    config.enable_schema_versions = true
    create_schema
  end

  # Not memoized: the restore replaces the connection pool, and a connection kept from
  # the old pool would reconnect on use and hold the database open
  delegate :connection, to: 'ActiveRecord::Base'

  def restore_database_config(db_config)
    ActiveRecord::DatabaseConfigurations::HashConfig.new(
      db_config.env_name, 'primary', db_config.configuration_hash.merge(database: "#{db_config.database}_restore")
    )
  end

  def load_rake_tasks
    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    Rake::Task.define_task('db:check_protected_environments')
    load File.expand_path('../../lib/tasks/better_structure_sql.rake', __dir__)
  end

  def create_schema
    connection.create_table(:better_structure_sql_schema_versions) do |t|
      t.text :content, null: false
      t.string :content_hash, limit: 32, null: false
      t.binary :zip_archive
      t.string :pg_version, null: false
      t.string :format_type, null: false
      t.string :output_mode, null: false
      t.bigint :content_size, null: false
      t.integer :line_count, null: false
      t.integer :file_count
      t.timestamps
    end
    connection.add_index(:better_structure_sql_schema_versions, :content_hash)
    connection.create_table(:bss_restore_posts) { |t| t.string :title, null: false }
    BetterStructureSql::SchemaVersion.reset_column_information
  end

  def dump_and_store(output_path)
    config.output_path = output_path
    BetterStructureSql::Dumper.new(config, connection).dump(store_version: false)
    BetterStructureSql::SchemaVersions.store_current(connection).version
  end

  def drift_from_stored_schema
    connection.create_table(:bss_restore_drift)
    connection.execute("INSERT INTO bss_restore_posts (title) VALUES ('lost')")
  end

  def restore(version)
    expect { Rake::Task['db:schema:restore'].invoke(version.id) }
      .to output(/Schema version #{version.id} restored/).to_stdout
  end

  shared_examples 'a schema replacement' do |output_path|
    it 'replaces the schema, data included, and records the environment' do
      version = dump_and_store(output_path)
      drift_from_stored_schema

      restore(version)

      expect(connection.tables).to include('bss_restore_posts', 'better_structure_sql_schema_versions')
      expect(connection.tables).not_to include('bss_restore_drift')
      expect(connection.index_exists?(:better_structure_sql_schema_versions, :content_hash)).to be true
      expect(connection.select_value('SELECT count(*) FROM bss_restore_posts')).to eq(0)
      expect(BetterStructureSql::SchemaVersion.count).to eq(0)
      expect(connection.select_rows('SELECT key, value FROM ar_internal_metadata ORDER BY key'))
        .to match([%w[environment test], ['schema_sha1', /\A\h{40}\z/]])
    end
  end

  context 'with a single-file version' do
    it_behaves_like 'a schema replacement', 'db/structure.sql'
  end

  context 'with a multi-file version' do
    it_behaves_like 'a schema replacement', 'db/schema'
  end

  it 'leaves the database purged, not half restored, when the stored schema does not load' do
    version = BetterStructureSql::SchemaVersions.store(
      content: 'THIS IS NOT SQL;', content_hash: Digest::MD5.hexdigest('THIS IS NOT SQL;'), format_type: 'sql', pg_version: '17.0'
    )

    expect { Rake::Task['db:schema:restore'].invoke(version.id) }.to raise_error(ActiveRecord::StatementInvalid)
    expect(connection.tables).to be_empty
  end
end
