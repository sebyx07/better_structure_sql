# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'

RSpec.describe BetterStructureSql::Dumper do
  let(:connection) { ActiveRecord::Base.connection }
  let(:temp_dir)   { Pathname.new(Dir.mktmpdir) }
  let(:config) do
    BetterStructureSql::Configuration.new.tap do |c|
      c.output_path = temp_dir.join('structure.sql')
      c.enable_schema_versions = true
    end
  end
  let(:dumper) { described_class.new(config, connection) }

  after { FileUtils.rm_rf(temp_dir) }

  # PostgreSQL makes the INSERT idempotent; SQLite loads into a purged database
  def migrations_insert_suffix
    connection.adapter_name.match?(/postg/i) ? 'ON CONFLICT DO NOTHING;' : ';'
  end

  # Versions in schema_migrations after executing a single-file SQLite dump in an empty database
  def loaded_migration_versions(path)
    database = SQLite3::Database.new(':memory:')
    database.execute_batch(File.read(path))
    database.execute('SELECT version FROM schema_migrations ORDER BY version').flatten
  ensure
    database&.close
  end

  def record_schema_migrations(versions)
    connection.execute('DELETE FROM schema_migrations')
    versions.each { |v| connection.execute("INSERT INTO schema_migrations (version) VALUES ('#{v}')") }
  end

  describe 'storing a schema version' do
    it 'stores the single-file dump with its content hash' do
      output = dumper.dump(store_version: true)

      version = BetterStructureSql::SchemaVersion.latest
      expect(version.content).to eq(output)
      expect(version.content_hash).to eq(Digest::MD5.hexdigest(output))
      expect(version.output_mode).to eq('single_file')
    end

    it 'stores when versioning is enabled and no explicit choice is made' do
      expect { dumper.dump }.to change(BetterStructureSql::SchemaVersion, :count).by(1)
    end

    it 'does not store an unchanged schema twice' do
      dumper.dump(store_version: true)

      expect { dumper.dump(store_version: true) }.not_to change(BetterStructureSql::SchemaVersion, :count)
    end

    it 'does not store when versioning is disabled' do
      config.enable_schema_versions = false

      expect { dumper.dump(store_version: true) }.not_to change(BetterStructureSql::SchemaVersion, :count)
    end

    it 'raises instead of hiding a storage failure' do
      allow(BetterStructureSql::SchemaVersions).to receive(:store_current)
        .and_raise(BetterStructureSql::Error, 'Schema versions table does not exist')

      expect { dumper.dump(store_version: true) }.to raise_error(BetterStructureSql::Error, /does not exist/)
    end

    context 'with multi-file output' do
      before { config.output_path = temp_dir.join('schema') }

      it 'stores a ZIP of the dumped directory and keeps the directory' do
        file_map = dumper.dump(store_version: true)

        version = BetterStructureSql::SchemaVersion.latest
        expect(version.output_mode).to eq('multi_file')
        expect(version.zip_archive).to be_present
        expect(version.content).to include('COMMENT ON').or include('CREATE TABLE')
        expect(file_map.keys).to all(satisfy { |path| temp_dir.join('schema', path).file? })
      end
    end
  end

  describe 'multi-file output' do
    before do
      config.output_path = temp_dir.join('schema')
      config.enable_schema_versions = false
    end

    it 'removes a manifest left by an earlier dump when manifests are disabled' do
      dumper.dump
      config.generate_manifest = false

      dumper.dump

      expect(temp_dir.join('schema', '_manifest.json')).not_to exist
    end

    it 'removes files of objects that were dropped since the last dump' do
      connection.execute('CREATE VIEW bss_stale_view AS SELECT 1 AS one')
      dumper.dump
      connection.execute('DROP VIEW bss_stale_view')

      dumper.dump

      expect(temp_dir.join('schema', '08_views')).not_to exist
    end

    it 'dumps migrations even when max_lines_per_file is smaller than an INSERT statement' do
      record_schema_migrations(%w[20240101000000 20240102000000])
      config.max_lines_per_file = 2

      file_map = dumper.dump

      inserts = file_map.select { |path, _| path.start_with?('20_migrations/') }.values
      expect(inserts.join("\n")).to include("('20240101000000')").and include("('20240102000000')")
      expect(inserts).to all(end_with(migrations_insert_suffix))
    end
  end

  describe 'relation-dependent objects' do
    before do
      skip 'requires a PostgreSQL DATABASE_URL' unless connection.adapter_name.match?(/postg/i)
      config.enable_schema_versions = false
      connection.execute(<<~SQL)
        CREATE VIEW bss_view AS SELECT 1 AS one;
        CREATE MATERIALIZED VIEW bss_matview AS SELECT 2 AS two;
        CREATE FUNCTION bss_plain() RETURNS integer LANGUAGE sql AS $$ SELECT 1 $$;
      SQL
    end

    it 'keeps the fixed functions, views, materialized views layout when nothing crosses sections' do
      titles = dumper.dump.lines.grep(/^-- /).map(&:strip)

      expect(titles.count('-- Functions')).to eq(1)
      expect(titles.index('-- Functions')).to be < titles.index('-- Tables')
      expect(titles.each_cons(2)).to include(['-- Views', '-- Materialized Views'])
    end

    it 'moves a function that needs a view behind that view' do
      connection.execute('CREATE FUNCTION bss_rows() RETURNS SETOF bss_view LANGUAGE sql AS $$ SELECT * FROM bss_view $$')

      output = dumper.dump

      expect(output.index('"bss_view"')).to be < output.index('FUNCTION public.bss_rows')
      expect(output.index('FUNCTION public.bss_plain')).to be < output.index('-- Tables')
    end

    it 'honours the include toggles' do
      connection.execute('CREATE FUNCTION bss_rows() RETURNS SETOF bss_view LANGUAGE sql AS $$ SELECT * FROM bss_view $$')
      config.include_views = false
      config.include_functions = false

      output = dumper.dump

      expect(output).to include('bss_matview')
      expect(%w[bss_view bss_rows bss_plain].select { |name| output.include?(name) }).to be_empty
    end

    it 'writes them in dependency order into the views directory in multi-file mode' do
      connection.execute('CREATE FUNCTION bss_rows() RETURNS SETOF bss_view LANGUAGE sql AS $$ SELECT * FROM bss_view $$')
      config.output_path = temp_dir.join('schema')

      file_map = dumper.dump

      views = file_map.fetch('08_views/000001.sql')
      expect(views.index('"bss_view"')).to be < views.index('FUNCTION public.bss_rows')
      expect(file_map.fetch('03_functions/000001.sql')).to include('bss_plain').and(satisfy { |sql| sql.exclude?('bss_rows') })
    end
  end

  describe 'schema migrations' do
    before { config.enable_schema_versions = false }

    it 'emits one sorted INSERT in single-file mode' do
      record_schema_migrations(%w[20240102000000 20240101000000])

      expect(dumper.dump).to include(<<~SQL.strip)
        -- Schema Migrations
        INSERT INTO "schema_migrations" (version) VALUES
        ('20240101000000'),
        ('20240102000000')
        #{migrations_insert_suffix}
      SQL
    end

    it 'dumps the schema_migrations table the INSERT needs' do
      expect(dumper.dump).to match(/^CREATE TABLE (IF NOT EXISTS )?"schema_migrations" \(/)
    end

    it 'leaves no migration pending after the dump is loaded into an empty database' do
      skip 'loads into a second in-memory database; needs the SQLite default' unless connection.adapter_name.match?(/sqlite/i)
      record_schema_migrations(%w[20240101000000 20240102000000])
      dumper.dump

      versions = loaded_migration_versions(config.output_path)

      expect(versions).to eq(%w[20240101000000 20240102000000])
    end

    it 'splits large migration lists into loadable INSERT statements per file' do
      record_schema_migrations(Array.new(25) { |i| format('202401%08d', i) })
      config.output_path = temp_dir.join('schema')
      config.max_lines_per_file = 13

      file_map = dumper.dump

      inserts = file_map.select { |path, _| path.start_with?('20_migrations/') }.values
      expect(inserts.size).to eq(3)
      expect(inserts).to all(start_with('INSERT INTO "schema_migrations" (version) VALUES'))
      expect(inserts.sum { |sql| sql.scan(/\('\d+'\)/).size }).to eq(25)
    end

    it 'escapes quotes in version values' do
      record_schema_migrations(['2024'])
      connection.execute("INSERT INTO schema_migrations (version) VALUES ('it''s')")

      expect(dumper.dump).to include("('it''s')")
    end
  end
end
