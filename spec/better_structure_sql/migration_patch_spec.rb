# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'

RSpec.describe BetterStructureSql::MigrationPatch do
  let(:temp_dir)   { Pathname.new(Dir.mktmpdir) }
  let(:schema_dir) { temp_dir.join('db/schema').to_s }
  let(:config)     { BetterStructureSql.configuration }

  around do |example|
    original_config = BetterStructureSql.configuration
    original_format = ActiveRecord.schema_format
    BetterStructureSql.configuration = BetterStructureSql::Configuration.new
    ActiveRecord.schema_format = :sql
    example.run
  ensure
    BetterStructureSql.configuration = original_config
    ActiveRecord.schema_format = original_format
    FileUtils.rm_rf(temp_dir)
  end

  before do
    allow(Rails).to receive(:root).and_return(temp_dir)
    config.output_path = 'db/schema'
    FileUtils.mkdir_p(File.join(schema_dir, '05_tables'))
    File.write(File.join(schema_dir, '05_tables/000001.sql'), 'CREATE TABLE bss_patch_users (id bigint);')
  end

  describe 'maintain_test_schema!' do
    # Stands in for ActiveRecord::Migration without patching the real singleton
    let(:rails_migration) do
      Module.new do
        def calls
          @calls ||= []
        end

        def maintain_test_schema!
          calls << :rails_maintain_test_schema
        end

        def check_pending_migrations
          calls << :check_pending_migrations
        end
      end
    end
    let(:migration) { Object.new.extend(rails_migration).extend(described_class::MaintainTestSchemaPatch) }
    let(:tasks)     { ActiveRecord::Tasks::DatabaseTasks }
    let(:db_config) { ActiveRecord::Base.connection_db_config }

    before do
      allow(tasks).to receive(:purge)
      allow(tasks).to receive(:load_schema)
      allow(tasks).to receive(:schema_up_to_date?).and_return(false)
      allow(ActiveRecord::Base).to receive(:establish_connection)
    end

    it 'leaves the refresh to Rails when replace_default_load is on' do
      config.replace_default_load = true

      migration.maintain_test_schema!

      expect(migration.calls).to eq([:rails_maintain_test_schema])
      expect(tasks).not_to have_received(:purge)
    end

    it 'leaves the refresh to Rails when replace_default_dump points Rails at the directory' do
      config.replace_default_dump = true

      migration.maintain_test_schema!

      expect(migration.calls).to eq([:rails_maintain_test_schema])
    end

    it 'leaves a single-file schema to Rails' do
      config.output_path = 'db/structure.sql'

      migration.maintain_test_schema!

      expect(migration.calls).to eq([:rails_maintain_test_schema])
    end

    it 'reloads a stale directory schema through Rails, which records the environment and checksum' do
      migration.maintain_test_schema!

      expect(tasks).to have_received(:schema_up_to_date?).with(db_config, :sql, schema_dir).ordered
      expect(tasks).to have_received(:purge).with(db_config).ordered
      expect(ActiveRecord::Base).to have_received(:establish_connection).with(db_config).ordered
      expect(tasks).to have_received(:load_schema).with(db_config, :sql, schema_dir).ordered
      expect(migration.calls).to eq([:check_pending_migrations])
    end

    it 'keeps an up-to-date test database but still checks for pending migrations' do
      allow(tasks).to receive(:schema_up_to_date?).and_return(true)

      migration.maintain_test_schema!

      expect(tasks).not_to have_received(:purge)
      expect(migration.calls).to eq([:check_pending_migrations])
    end

    it 'does nothing when maintain_test_schema is off' do
      allow(ActiveRecord).to receive(:maintain_test_schema).and_return(false)

      migration.maintain_test_schema!

      expect(tasks).not_to have_received(:purge)
      expect(migration.calls).to eq([:rails_maintain_test_schema])
    end
  end

  describe 'DatabaseTasksPatch' do
    # Stands in for ActiveRecord::Tasks::DatabaseTasks without patching the real singleton
    let(:rails_tasks) do
      Module.new do
        def structure_load(_db_config, filename, *)
          "rails loaded #{filename}"
        end

        def schema_sha1(file)
          "rails sha1 of #{file}"
        end
      end
    end
    let(:tasks) { Object.new.extend(rails_tasks).extend(described_class::DatabaseTasksPatch) }

    after { ActiveRecord::Base.connection.drop_table(:bss_patch_users, if_exists: true) }

    it 'loads a schema directory with the schema loader' do
      tasks.structure_load(ActiveRecord::Base.connection_db_config, schema_dir)

      expect(ActiveRecord::Base.connection.table_exists?(:bss_patch_users)).to be true
    end

    it 'leaves a schema file to Rails' do
      expect(tasks.structure_load(nil, 'db/structure.sql')).to eq('rails loaded db/structure.sql')
    end

    it 'checksums every SQL file of a directory' do
      checksum = tasks.schema_sha1(schema_dir)
      File.write(File.join(schema_dir, '_header.sql'), 'SET check_function_bodies = false;')

      expect(checksum).to match(/\A\h{40}\z/)
      expect(tasks.schema_sha1(schema_dir)).not_to eq(checksum)
    end

    it 'leaves the checksum of a file to Rails' do
      expect(tasks.schema_sha1('db/structure.sql')).to eq('rails sha1 of db/structure.sql')
    end
  end
end
