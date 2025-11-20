# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'digest'

RSpec.describe BetterStructureSql::SchemaVersions do
  let(:connection) { double('connection') }
  let(:rails_root) { Pathname.new(Dir.tmpdir) }

  before do
    # Stub ActiveRecord::Base.connection to return our mock connection
    allow(ActiveRecord::Base).to receive(:connection).and_return(connection)

    # Stub Rails.root for file operations
    rails_double = double('Rails', root: rails_root)
    stub_const('Rails', rails_double)
  end

  describe '.store' do
    it 'stores a schema version with given parameters' do
      content = 'CREATE TABLE users (id serial);'
      content_hash = Digest::MD5.hexdigest(content)
      format_type = 'sql'
      pg_version = '14.5'

      # Mock the table existence check
      allow(connection).to receive(:table_exists?)
        .with('better_structure_sql_schema_versions')
        .and_return(true)

      # Mock the create
      version = instance_double(BetterStructureSql::SchemaVersion, id: 1)
      allow(BetterStructureSql::SchemaVersion).to receive(:create!)
        .and_return(version)

      result = described_class.store(
        content: content,
        content_hash: content_hash,
        format_type: format_type,
        pg_version: pg_version,
        connection: connection
      )

      expect(result).to eq(version)
    end

    it 'raises error when table does not exist' do
      allow(connection).to receive(:table_exists?)
        .with('better_structure_sql_schema_versions')
        .and_return(false)

      expect do
        described_class.store(
          content: 'CREATE TABLE users',
          content_hash: Digest::MD5.hexdigest('CREATE TABLE users'),
          format_type: 'sql',
          output_mode: 'single_file',
          pg_version: '14.5',
          connection: connection
        )
      end.to raise_error(BetterStructureSql::Error, /Schema versions table does not exist/)
    end
  end

  describe '.latest' do
    it 'returns nil when table does not exist' do
      allow(described_class).to receive(:table_exists?).and_return(false)
      expect(described_class.latest).to be_nil
    end

    it 'returns latest version when table exists' do
      allow(described_class).to receive(:table_exists?).and_return(true)
      version = instance_double(BetterStructureSql::SchemaVersion)
      allow(BetterStructureSql::SchemaVersion).to receive(:latest).and_return(version)

      expect(described_class.latest).to eq(version)
    end
  end

  describe '.all_versions' do
    it 'returns empty array when table does not exist' do
      allow(described_class).to receive(:table_exists?).and_return(false)
      expect(described_class.all_versions).to eq([])
    end

    it 'returns all versions ordered by created_at DESC' do
      allow(described_class).to receive(:table_exists?).and_return(true)
      versions = [
        instance_double(BetterStructureSql::SchemaVersion),
        instance_double(BetterStructureSql::SchemaVersion)
      ]
      relation = double('relation')
      allow(BetterStructureSql::SchemaVersion).to receive(:order).with(created_at: :desc).and_return(relation)
      allow(relation).to receive(:to_a).and_return(versions)

      expect(described_class.all_versions).to eq(versions)
    end
  end

  describe '.count' do
    it 'returns 0 when table does not exist' do
      allow(described_class).to receive(:table_exists?).and_return(false)
      expect(described_class.count).to eq(0)
    end

    it 'returns count when table exists' do
      allow(described_class).to receive(:table_exists?).and_return(true)
      allow(BetterStructureSql::SchemaVersion).to receive(:count).and_return(5)

      expect(described_class.count).to eq(5)
    end
  end

  describe '.by_format' do
    it 'returns empty array when table does not exist' do
      allow(described_class).to receive(:table_exists?).and_return(false)
      expect(described_class.by_format('sql')).to eq([])
    end

    it 'returns versions filtered by format_type' do
      allow(described_class).to receive(:table_exists?).and_return(true)
      versions = [instance_double(BetterStructureSql::SchemaVersion)]
      scope = double('scope')
      relation = double('relation')

      allow(BetterStructureSql::SchemaVersion).to receive(:by_format).with('sql').and_return(scope)
      allow(scope).to receive(:order).with(created_at: :desc).and_return(relation)
      allow(relation).to receive(:to_a).and_return(versions)

      expect(described_class.by_format('sql')).to eq(versions)
    end
  end

  describe '.cleanup!' do
    it 'returns 0 when table does not exist' do
      allow(described_class).to receive(:table_exists?).and_return(false)
      expect(described_class.cleanup!(connection)).to eq(0)
    end

    it 'returns 0 when limit is 0 (unlimited)' do
      allow(described_class).to receive(:table_exists?).and_return(true)
      config = instance_double(BetterStructureSql::Configuration, schema_versions_limit: 0)
      allow(BetterStructureSql).to receive(:configuration).and_return(config)

      expect(described_class.cleanup!(connection)).to eq(0)
    end

    it 'returns 0 when count is within limit' do
      allow(described_class).to receive(:table_exists?).and_return(true)
      config = instance_double(BetterStructureSql::Configuration, schema_versions_limit: 10)
      allow(BetterStructureSql).to receive(:configuration).and_return(config)
      allow(BetterStructureSql::SchemaVersion).to receive(:count).and_return(5)

      expect(described_class.cleanup!(connection)).to eq(0)
    end

    it 'deletes oldest versions beyond limit' do
      allow(described_class).to receive(:table_exists?).and_return(true)
      config = instance_double(BetterStructureSql::Configuration, schema_versions_limit: 3)
      allow(BetterStructureSql).to receive(:configuration).and_return(config)

      version1 = instance_double(BetterStructureSql::SchemaVersion)
      version2 = instance_double(BetterStructureSql::SchemaVersion)
      relation = double('relation')

      allow(BetterStructureSql::SchemaVersion).to receive_messages(count: 5, oldest_first: relation)
      allow(relation).to receive(:limit).with(2).and_return([version1, version2])
      allow(version1).to receive(:destroy)
      allow(version2).to receive(:destroy)

      expect(described_class.cleanup!(connection)).to eq(2)
    end
  end

  describe '.calculate_hash' do
    it 'returns 32-character MD5 hexdigest' do
      content = 'CREATE TABLE users (id serial);'
      hash = described_class.calculate_hash(content)

      expect(hash).to be_a(String)
      expect(hash.length).to eq(32)
      expect(hash).to match(/\A[a-f0-9]{32}\z/)
    end

    it 'returns same hash for identical content' do
      content = 'CREATE TABLE users (id serial);'
      hash1 = described_class.calculate_hash(content)
      hash2 = described_class.calculate_hash(content)

      expect(hash1).to eq(hash2)
    end

    it 'returns different hash for different content' do
      content1 = 'CREATE TABLE users (id serial);'
      content2 = 'CREATE TABLE posts (id serial);'
      hash1 = described_class.calculate_hash(content1)
      hash2 = described_class.calculate_hash(content2)

      expect(hash1).not_to eq(hash2)
    end

    it 'handles empty string content' do
      hash = described_class.calculate_hash('')
      expect(hash).to eq('d41d8cd98f00b204e9800998ecf8427e') # MD5 of empty string
    end

    it 'handles large content (5MB+)' do
      large_content = 'X' * (5 * 1024 * 1024)
      hash = described_class.calculate_hash(large_content)

      expect(hash).to be_a(String)
      expect(hash.length).to eq(32)
    end

    it 'handles UTF-8 content correctly' do
      unicode_content = 'CREATE TABLE users (name VARCHAR(255) DEFAULT \'José\');'
      hash = described_class.calculate_hash(unicode_content)

      expect(hash).to be_a(String)
      expect(hash.length).to eq(32)
    end

    it 'raises ArgumentError when content is nil' do
      expect { described_class.calculate_hash(nil) }.to raise_error(ArgumentError, 'Content cannot be nil')
    end
  end

  describe '.calculate_hash_from_file' do
    let(:temp_file) { Tempfile.new('schema.sql') }

    after { temp_file.unlink }

    it 'calculates hash from single file' do
      content = 'CREATE TABLE users (id serial);'
      temp_file.write(content)
      temp_file.rewind

      hash = described_class.calculate_hash_from_file(temp_file.path)

      expect(hash).to eq(described_class.calculate_hash(content))
    end

    it 'returns same hash as calculate_hash for same content' do
      content = 'CREATE TABLE users (id serial);'
      temp_file.write(content)
      temp_file.rewind

      hash_from_file = described_class.calculate_hash_from_file(temp_file.path)
      hash_from_content = described_class.calculate_hash(content)

      expect(hash_from_file).to eq(hash_from_content)
    end

    it 'raises error if file not found' do
      expect do
        described_class.calculate_hash_from_file('nonexistent.sql')
      end.to raise_error(Errno::ENOENT, /File not found/)
    end
  end

  describe '.calculate_hash_from_directory' do
    let(:temp_dir) { Dir.mktmpdir }

    after { FileUtils.rm_rf(temp_dir) }

    it 'calculates hash from multi-file directory' do
      # Create directory structure
      FileUtils.mkdir_p(File.join(temp_dir, '01_tables'))
      File.write(File.join(temp_dir, '_header.sql'), '-- Header')
      File.write(File.join(temp_dir, '01_tables', '000001.sql'), 'CREATE TABLE users (id serial);')

      hash = described_class.calculate_hash_from_directory(temp_dir)

      expect(hash).to be_a(String)
      expect(hash.length).to eq(32)
    end

    it 'raises error if directory not found' do
      expect do
        described_class.calculate_hash_from_directory('nonexistent_dir')
      end.to raise_error(Errno::ENOENT, /Directory not found/)
    end
  end

  describe '.read_and_hash_content' do
    let(:temp_file) { Tempfile.new('schema.sql') }

    after { temp_file.unlink }

    it 'returns content, hash, zip_archive, and file_count for single file' do
      content = 'CREATE TABLE users (id serial);'
      temp_file.write(content)
      temp_file.rewind

      result_content, result_hash, zip_archive, file_count = described_class.read_and_hash_content(
        temp_file.path,
        'single_file'
      )

      expect(result_content).to eq(content)
      expect(result_hash).to eq(described_class.calculate_hash(content))
      expect(zip_archive).to be_nil
      expect(file_count).to be_nil
    end

    it 'returns nil values when file not found' do
      result_content, result_hash, zip_archive, file_count = described_class.read_and_hash_content(
        'nonexistent.sql',
        'single_file'
      )

      expect(result_content).to be_nil
      expect(result_hash).to be_nil
      expect(zip_archive).to be_nil
      expect(file_count).to be_nil
    end
  end

  describe '.latest_hash' do
    it 'returns hash of most recent version' do
      allow(described_class).to receive(:table_exists?).and_return(true)
      version = double('SchemaVersion', content_hash: 'abc123')
      allow(BetterStructureSql::SchemaVersion).to receive(:latest).and_return(version)

      expect(described_class.latest_hash(connection)).to eq('abc123')
    end

    it 'returns nil when no versions exist' do
      allow(described_class).to receive(:table_exists?).and_return(true)
      allow(BetterStructureSql::SchemaVersion).to receive(:latest).and_return(nil)

      expect(described_class.latest_hash(connection)).to be_nil
    end

    it 'returns nil when table does not exist' do
      allow(described_class).to receive(:table_exists?).and_return(false)

      expect(described_class.latest_hash(connection)).to be_nil
    end
  end

  describe '.hash_exists?' do
    it 'returns true when hash found' do
      allow(described_class).to receive(:table_exists?).and_return(true)
      relation = double('relation')
      allow(BetterStructureSql::SchemaVersion).to receive(:where).with(content_hash: 'abc123').and_return(relation)
      allow(relation).to receive(:exists?).and_return(true)

      expect(described_class.hash_exists?('abc123', connection)).to be true
    end

    it 'returns false when hash not found' do
      allow(described_class).to receive(:table_exists?).and_return(true)
      relation = double('relation')
      allow(BetterStructureSql::SchemaVersion).to receive(:where).with(content_hash: 'xyz789').and_return(relation)
      allow(relation).to receive(:exists?).and_return(false)

      expect(described_class.hash_exists?('xyz789', connection)).to be false
    end

    it 'returns false when table does not exist' do
      allow(described_class).to receive(:table_exists?).and_return(false)

      expect(described_class.hash_exists?('abc123', connection)).to be false
    end
  end

  describe '.find_by_hash' do
    it 'finds version by content_hash' do
      allow(described_class).to receive(:table_exists?).and_return(true)
      version = instance_double(BetterStructureSql::SchemaVersion)
      relation = double('relation')
      order_relation = double('order_relation')
      allow(BetterStructureSql::SchemaVersion).to receive(:where).with(content_hash: 'abc123').and_return(relation)
      allow(relation).to receive(:order).with(created_at: :desc).and_return(order_relation)
      allow(order_relation).to receive(:first).and_return(version)

      expect(described_class.find_by_hash('abc123', connection)).to eq(version)
    end

    it 'returns nil when hash not found' do
      allow(described_class).to receive(:table_exists?).and_return(true)
      relation = double('relation')
      order_relation = double('order_relation')
      allow(BetterStructureSql::SchemaVersion).to receive(:where).with(content_hash: 'xyz789').and_return(relation)
      allow(relation).to receive(:order).with(created_at: :desc).and_return(order_relation)
      allow(order_relation).to receive(:first).and_return(nil)

      expect(described_class.find_by_hash('xyz789', connection)).to be_nil
    end

    it 'returns nil when table does not exist' do
      allow(described_class).to receive(:table_exists?).and_return(false)

      expect(described_class.find_by_hash('abc123', connection)).to be_nil
    end

    it 'returns most recent version if multiple match' do
      allow(described_class).to receive(:table_exists?).and_return(true)
      version = instance_double(BetterStructureSql::SchemaVersion)
      relation = double('relation')
      order_relation = double('order_relation')
      allow(BetterStructureSql::SchemaVersion).to receive(:where).with(content_hash: 'abc123').and_return(relation)
      allow(relation).to receive(:order).with(created_at: :desc).and_return(order_relation)
      allow(order_relation).to receive(:first).and_return(version)

      result = described_class.find_by_hash('abc123', connection)
      expect(result).to eq(version)
    end
  end
end
