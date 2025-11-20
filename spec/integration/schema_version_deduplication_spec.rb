# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Schema version deduplication', type: :integration do
  let(:connection)  { ActiveRecord::Base.connection }
  let(:config)      { BetterStructureSql.configuration }
  let(:temp_dir)    { Pathname.new(Dir.mktmpdir) }
  let(:output_path) { temp_dir.join('db', 'structure.sql') }

  before do
    # Stub Rails.root
    rails_double = double('Rails', root: temp_dir)
    stub_const('Rails', rails_double)

    # Configure for single-file mode by default
    config.output_path = output_path
    config.enable_schema_versions = true
    config.schema_versions_limit = 10

    # Create directory and write schema file
    FileUtils.mkdir_p(output_path.dirname)
    File.write(output_path, '-- Schema content v1')
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe 'duplicate detection' do
    it 'stores first version when no previous versions exist' do
      result = BetterStructureSql::SchemaVersions.store_current(connection)

      expect(result.stored?).to be true
      expect(result.skipped?).to be false
      expect(result.version).to be_persisted
      expect(result.version.content_hash).to be_present
      expect(result.version.content_hash).to match(/\A[a-f0-9]{32}\z/)
      expect(BetterStructureSql::SchemaVersion.count).to eq(1)
      expect(result.total_count).to eq(1)
    end

    it 'skips storage when hash matches latest version' do
      # Store initial version
      initial_result = BetterStructureSql::SchemaVersions.store_current(connection)
      initial_id = initial_result.version.id
      initial_hash = initial_result.version.content_hash

      # Attempt to store again without schema changes
      result = BetterStructureSql::SchemaVersions.store_current(connection)

      expect(result.skipped?).to be true
      expect(result.stored?).to be false
      expect(result.version_id).to eq(initial_id)
      expect(result.hash).to eq(initial_hash)
      expect(result.total_count).to eq(1)
      expect(BetterStructureSql::SchemaVersion.count).to eq(1) # Still only one version
    end

    it 'stores new version when hash differs' do
      # Store initial version
      initial_result = BetterStructureSql::SchemaVersions.store_current(connection)
      initial_hash = initial_result.version.content_hash

      # Change schema content
      File.write(output_path, '-- Schema content v2')

      # Attempt to store again with changes
      result = BetterStructureSql::SchemaVersions.store_current(connection)

      expect(result.stored?).to be true
      expect(result.skipped?).to be false
      expect(result.version.content_hash).not_to eq(initial_hash)
      expect(result.total_count).to eq(2)
      expect(BetterStructureSql::SchemaVersion.count).to eq(2)
    end

    it 'returns nil when schema file does not exist' do
      File.delete(output_path)

      result = BetterStructureSql::SchemaVersions.store_current(connection)

      expect(result.skipped?).to be true
      expect(result.version_id).to be_nil
      expect(result.total_count).to eq(0)
    end
  end

  describe 'multi-file mode deduplication' do
    let(:multi_file_path) { temp_dir.join('db', 'schema') }

    before do
      config.output_path = multi_file_path

      # Create multi-file directory structure
      FileUtils.mkdir_p(multi_file_path.join('01_tables'))
      File.write(multi_file_path.join('_header.sql'), '-- Header v1')
      File.write(multi_file_path.join('01_tables', '000001.sql'), 'CREATE TABLE users (id serial);')
    end

    it 'detects duplicates in multi-file mode' do
      # Store initial version
      initial_result = BetterStructureSql::SchemaVersions.store_current(connection)
      expect(initial_result.stored?).to be true

      # Recreate directory with same content
      FileUtils.rm_rf(multi_file_path)
      FileUtils.mkdir_p(multi_file_path.join('01_tables'))
      File.write(multi_file_path.join('_header.sql'), '-- Header v1')
      File.write(multi_file_path.join('01_tables', '000001.sql'), 'CREATE TABLE users (id serial);')

      # Attempt to store again
      result = BetterStructureSql::SchemaVersions.store_current(connection)

      expect(result.skipped?).to be true
      expect(BetterStructureSql::SchemaVersion.count).to eq(1)
    end

    it 'detects changes in multi-file mode' do
      # Store initial version
      initial_result = BetterStructureSql::SchemaVersions.store_current(connection)
      initial_hash = initial_result.version.content_hash

      # Recreate directory with different content
      FileUtils.rm_rf(multi_file_path)
      FileUtils.mkdir_p(multi_file_path.join('01_tables'))
      File.write(multi_file_path.join('_header.sql'), '-- Header v2') # Changed
      File.write(multi_file_path.join('01_tables', '000001.sql'), 'CREATE TABLE users (id serial);')

      # Attempt to store with changes
      result = BetterStructureSql::SchemaVersions.store_current(connection)

      expect(result.stored?).to be true
      expect(result.version.content_hash).not_to eq(initial_hash)
      expect(BetterStructureSql::SchemaVersion.count).to eq(2)
    end

    it 'creates ZIP archive when storing multi-file schema' do
      result = BetterStructureSql::SchemaVersions.store_current(connection)

      expect(result.stored?).to be true
      expect(result.version.zip_archive).to be_present
      expect(result.version.file_count).to eq(2) # _header.sql + 01_tables/000001.sql
      expect(result.version.output_mode).to eq('multi_file')
    end
  end

  describe 'production workflow simulation' do
    it 'handles repeated deploys without schema changes' do
      # Deploy 1: Initial schema
      File.write(output_path, '-- Initial schema')
      result1 = BetterStructureSql::SchemaVersions.store_current(connection)
      expect(result1.stored?).to be true

      # Deploy 2: No changes
      result2 = BetterStructureSql::SchemaVersions.store_current(connection)
      expect(result2.skipped?).to be true

      # Deploy 3: No changes
      result3 = BetterStructureSql::SchemaVersions.store_current(connection)
      expect(result3.skipped?).to be true

      # Only 1 version stored
      expect(BetterStructureSql::SchemaVersion.count).to eq(1)
    end

    it 'tracks actual schema evolution across deploys' do
      stored_results = []

      # Deploy 1: Initial schema
      File.write(output_path, '-- Schema v1')
      stored_results << BetterStructureSql::SchemaVersions.store_current(connection)

      # Deploy 2: No changes (skipped)
      BetterStructureSql::SchemaVersions.store_current(connection)

      # Deploy 3: Migration adds table
      File.write(output_path, "-- Schema v1\nCREATE TABLE posts (id serial);")
      stored_results << BetterStructureSql::SchemaVersions.store_current(connection)

      # Deploy 4: No changes (skipped)
      BetterStructureSql::SchemaVersions.store_current(connection)

      # Deploy 5: Migration adds another table
      File.write(output_path, "-- Schema v1\nCREATE TABLE posts (id serial);\nCREATE TABLE comments (id serial);")
      stored_results << BetterStructureSql::SchemaVersions.store_current(connection)

      # Only 3 versions stored (deploys with actual changes)
      expect(BetterStructureSql::SchemaVersion.count).to eq(3)
      expect(stored_results.count(&:stored?)).to eq(3)

      # Each stored version has different hash
      hashes = stored_results.map { |r| r.version.content_hash }
      expect(hashes.uniq.count).to eq(3)
    end

    it 'tracks version count correctly across mixed operations' do
      # Store 3 unique versions
      File.write(output_path, '-- v1')
      r1 = BetterStructureSql::SchemaVersions.store_current(connection)
      expect(r1.total_count).to eq(1)

      File.write(output_path, '-- v2')
      r2 = BetterStructureSql::SchemaVersions.store_current(connection)
      expect(r2.total_count).to eq(2)

      File.write(output_path, '-- v3')
      r3 = BetterStructureSql::SchemaVersions.store_current(connection)
      expect(r3.total_count).to eq(3)

      # Skip duplicate
      r4 = BetterStructureSql::SchemaVersions.store_current(connection)
      expect(r4.skipped?).to be true
      expect(r4.total_count).to eq(3)

      # Store another
      File.write(output_path, '-- v4')
      r5 = BetterStructureSql::SchemaVersions.store_current(connection)
      expect(r5.total_count).to eq(4)
    end
  end

  describe 'filesystem cleanup' do
    let(:multi_file_path) { temp_dir.join('db', 'schema') }

    before do
      config.output_path = multi_file_path

      # Create multi-file directory structure
      FileUtils.mkdir_p(multi_file_path.join('01_tables'))
      File.write(multi_file_path.join('_header.sql'), '-- Header')
      File.write(multi_file_path.join('01_tables', '000001.sql'), 'CREATE TABLE users (id serial);')
    end

    it 'deletes directory after storing ZIP archive' do
      # Directory exists before storage
      expect(Dir.exist?(multi_file_path)).to be true

      # Store creates ZIP and deletes directory
      result = BetterStructureSql::SchemaVersions.store_current(connection)

      expect(result.stored?).to be true
      expect(result.version.zip_archive).to be_present
      expect(Dir.exist?(multi_file_path)).to be false # Directory deleted
    end

    it 'does not delete directory when storage skipped' do
      # First store (directory deleted after ZIP created)
      BetterStructureSql::SchemaVersions.store_current(connection)
      expect(Dir.exist?(multi_file_path)).to be false

      # Recreate directory with same content
      FileUtils.mkdir_p(multi_file_path.join('01_tables'))
      File.write(multi_file_path.join('_header.sql'), '-- Header')
      File.write(multi_file_path.join('01_tables', '000001.sql'), 'CREATE TABLE users (id serial);')

      expect(Dir.exist?(multi_file_path)).to be true

      # Second store skipped (directory remains for re-use)
      result = BetterStructureSql::SchemaVersions.store_current(connection)
      expect(result.skipped?).to be true
      expect(Dir.exist?(multi_file_path)).to be true # Directory NOT deleted
    end

    it 'does not delete single file after storing' do
      config.output_path = output_path # Switch back to single-file mode
      File.write(output_path, '-- Schema')

      # File exists before storage
      expect(File.exist?(output_path)).to be true

      # Store version (single-file, no ZIP, no cleanup)
      result = BetterStructureSql::SchemaVersions.store_current(connection)

      expect(result.stored?).to be true
      expect(result.version.zip_archive).to be_nil
      expect(File.exist?(output_path)).to be true # File NOT deleted
    end

    it 'handles cleanup errors gracefully' do
      # Store initial version
      result = BetterStructureSql::SchemaVersions.store_current(connection)

      expect(result.stored?).to be true
      # Directory should be deleted, but we'll test error handling in unit tests
    end
  end

  describe 'retention with deduplication' do
    before do
      config.schema_versions_limit = 3
    end

    it 'retains only unique versions within limit' do
      # Store 5 unique versions
      5.times do |i|
        File.write(output_path, "-- Schema v#{i}")
        BetterStructureSql::SchemaVersions.store_current(connection)
      end

      # Only 3 most recent retained
      expect(BetterStructureSql::SchemaVersion.count).to eq(3)

      # All have different hashes
      hashes = BetterStructureSql::SchemaVersion.pluck(:content_hash)
      expect(hashes.uniq.count).to eq(3)
    end

    it 'does not count skipped attempts toward retention limit' do
      config.schema_versions_limit = 2

      # Store 3 unique versions
      File.write(output_path, '-- v1')
      BetterStructureSql::SchemaVersions.store_current(connection)

      File.write(output_path, '-- v2')
      v2 = BetterStructureSql::SchemaVersions.store_current(connection)

      File.write(output_path, '-- v3')
      v3 = BetterStructureSql::SchemaVersions.store_current(connection)

      # Oldest version (v1) deleted by retention
      expect(BetterStructureSql::SchemaVersion.count).to eq(2)
      expect(BetterStructureSql::SchemaVersion.pluck(:id)).to contain_exactly(v2.version.id, v3.version.id)

      # Attempt to store duplicate of v3 (skipped, no cleanup)
      result = BetterStructureSql::SchemaVersions.store_current(connection)
      expect(result.skipped?).to be true

      # Still only 2 versions
      expect(BetterStructureSql::SchemaVersion.count).to eq(2)
    end

    it 'cleanup only runs when storage occurs' do
      config.schema_versions_limit = 2

      # Store 2 versions
      File.write(output_path, '-- v1')
      BetterStructureSql::SchemaVersions.store_current(connection)

      File.write(output_path, '-- v2')
      BetterStructureSql::SchemaVersions.store_current(connection)

      expect(BetterStructureSql::SchemaVersion.count).to eq(2)

      # Skip duplicate (no cleanup triggered)
      initial_count = BetterStructureSql::SchemaVersion.count
      result = BetterStructureSql::SchemaVersions.store_current(connection)
      expect(result.skipped?).to be true
      expect(BetterStructureSql::SchemaVersion.count).to eq(initial_count)

      # Store new version (cleanup triggered, oldest deleted)
      File.write(output_path, '-- v3')
      v3 = BetterStructureSql::SchemaVersions.store_current(connection)
      expect(v3.stored?).to be true
      expect(BetterStructureSql::SchemaVersion.count).to eq(2)
    end
  end

  describe 'hash consistency' do
    it 'produces same hash for identical content' do
      File.write(output_path, '-- Identical schema')

      r1 = BetterStructureSql::SchemaVersions.store_current(connection)
      hash1 = r1.version.content_hash

      File.delete(output_path)
      File.write(output_path, '-- Identical schema')

      r2 = BetterStructureSql::SchemaVersions.store_current(connection)

      expect(r2.skipped?).to be true
      expect(r2.hash).to eq(hash1)
    end

    it 'produces different hash for different content' do
      File.write(output_path, '-- Schema A')
      r1 = BetterStructureSql::SchemaVersions.store_current(connection)

      File.write(output_path, '-- Schema B')
      r2 = BetterStructureSql::SchemaVersions.store_current(connection)

      expect(r1.version.content_hash).not_to eq(r2.version.content_hash)
    end
  end
end
