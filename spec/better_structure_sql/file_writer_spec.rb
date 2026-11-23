# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BetterStructureSql::FileWriter do
  let(:config) { BetterStructureSql::Configuration.new }
  let(:writer) { described_class.new(config) }

  describe '#detect_output_mode' do
    it 'detects directory paths as multi-file' do
      expect(writer.detect_output_mode('db/schema')).to eq(:multi_file)
    end

    it 'detects paths ending with slash as multi-file' do
      expect(writer.detect_output_mode('db/schema/')).to eq(:multi_file)
    end

    it 'detects .sql files as single-file' do
      expect(writer.detect_output_mode('db/structure.sql')).to eq(:single_file)
    end

    it 'detects .rb files as single-file' do
      expect(writer.detect_output_mode('db/schema.rb')).to eq(:single_file)
    end
  end

  describe '#write_single_file' do
    let(:temp_dir) { Dir.mktmpdir }
    let(:file_path) { File.join(temp_dir, 'test.sql') }

    after { FileUtils.rm_rf(temp_dir) }

    it 'writes content to specified file' do
      allow(Rails).to receive(:root).and_return(Pathname.new(temp_dir))
      content = 'CREATE TABLE users (id bigint);'

      writer.write_single_file('test.sql', content)

      expect(File.read(file_path)).to eq(content)
    end

    it 'creates parent directories if needed' do
      allow(Rails).to receive(:root).and_return(Pathname.new(temp_dir))
      nested_path = 'nested/dir/test.sql'

      writer.write_single_file(nested_path, 'content')

      expect(File.exist?(File.join(temp_dir, nested_path))).to be true
    end
  end

  describe '#write_multi_file' do
    let(:temp_dir) { Dir.mktmpdir }
    let(:base_path) { 'db/schema' }
    let(:header)    { "SET client_encoding = 'UTF8';" }
    let(:sections) do
      {
        extensions: ['CREATE EXTENSION pgcrypto;'],
        types: ['CREATE TYPE user_role AS ENUM (\'admin\', \'user\');'],
        tables: ['CREATE TABLE users (id bigint);', 'CREATE TABLE posts (id bigint);']
      }
    end

    before { allow(Rails).to receive(:root).and_return(Pathname.new(temp_dir)) }
    after { FileUtils.rm_rf(temp_dir) }

    it 'creates directory structure' do
      writer.write_multi_file(base_path, sections, header)

      expect(Dir.exist?(File.join(temp_dir, base_path, '01_extensions'))).to be true
      expect(Dir.exist?(File.join(temp_dir, base_path, '02_types'))).to be true
      expect(Dir.exist?(File.join(temp_dir, base_path, '05_tables'))).to be true
    end

    it 'writes header file' do
      writer.write_multi_file(base_path, sections, header)

      header_content = File.read(File.join(temp_dir, base_path, '_header.sql'))
      expect(header_content).to eq(header)
    end

    it 'writes numbered SQL files' do
      writer.write_multi_file(base_path, sections, header)

      expect(File.exist?(File.join(temp_dir, base_path, '01_extensions', '000001.sql'))).to be true
      expect(File.exist?(File.join(temp_dir, base_path, '02_types', '000001.sql'))).to be true
      expect(File.exist?(File.join(temp_dir, base_path, '05_tables', '000001.sql'))).to be true
    end

    it 'returns file map for manifest' do
      file_map = writer.write_multi_file(base_path, sections, header)

      expect(file_map).to be_a(Hash)
      expect(file_map.keys).to include('01_extensions/000001.sql')
      expect(file_map.keys).to include('02_types/000001.sql')
    end

    it 'chunks sections exceeding max lines' do
      config.max_lines_per_file = 2
      large_sections = {
        tables: [
          "CREATE TABLE t1 (id bigint);\n",
          "CREATE TABLE t2 (id bigint);\n",
          "CREATE TABLE t3 (id bigint);\n"
        ]
      }

      writer.write_multi_file(base_path, large_sections, header)

      # Should create multiple files
      tables_dir = File.join(temp_dir, base_path, '05_tables')
      files = Dir.glob(File.join(tables_dir, '*.sql'))
      expect(files.length).to be >= 2
    end
  end

  describe '#write_multi_file with a previous dump on disk' do
    let(:temp_dir) { Dir.mktmpdir }
    let(:base_path)  { 'db/schema' }
    let(:schema_dir) { Pathname.new(temp_dir).join(base_path) }

    before do
      allow(Rails).to receive(:root).and_return(Pathname.new(temp_dir))
      config.max_lines_per_file = 1
      writer.write_multi_file(
        base_path,
        { tables: ['CREATE TABLE a (id bigint);', 'CREATE TABLE b (id bigint);'], views: ['CREATE VIEW v AS SELECT 1;'] },
        '-- header'
      )
    end

    after { FileUtils.rm_rf(temp_dir) }

    it 'removes chunk files the smaller dump no longer produces' do
      writer.write_multi_file(base_path, { tables: ['CREATE TABLE a (id bigint);'], views: ['CREATE VIEW v AS SELECT 1;'] }, '-- header')

      expect(schema_dir.join('05_tables').children.map { |f| f.basename.to_s }).to eq(['000001.sql'])
    end

    it 'removes directories of sections that no longer exist' do
      writer.write_multi_file(base_path, { tables: ['CREATE TABLE a (id bigint);'] }, '-- header')

      expect(schema_dir.join('08_views')).not_to exist
    end

    it 'keeps files it does not own' do
      FileUtils.touch(schema_dir.join('_schema_cache.yml'))
      FileUtils.touch(schema_dir.join('05_tables', 'NOTES.md'))

      writer.write_multi_file(base_path, { tables: ['CREATE TABLE a (id bigint);'] }, '-- header')

      expect(schema_dir.join('_schema_cache.yml')).to exist
      expect(schema_dir.join('05_tables', 'NOTES.md')).to exist
    end

    it 'writes an empty header when the adapter has none' do
      writer.write_multi_file(base_path, { tables: ['CREATE TABLE a (id bigint);'] }, nil)

      expect(schema_dir.join('_header.sql').read).to eq('')
    end
  end

  describe '#write_manifest' do
    let(:temp_dir) { Dir.mktmpdir }
    let(:manifest_path) { File.join(temp_dir, 'db/schema/_manifest.json') }

    before do
      allow(Rails).to receive(:root).and_return(Pathname.new(temp_dir))
      FileUtils.mkdir_p(File.dirname(manifest_path))
    end

    after { FileUtils.rm_rf(temp_dir) }

    it 'writes the manifest content' do
      writer.write_manifest('db/schema', '{}')

      expect(File.read(manifest_path)).to eq('{}')
    end

    it 'removes a leftover manifest when there is no content' do
      File.write(manifest_path, '{"total_files": 99}')

      writer.write_manifest('db/schema', nil)

      expect(File.exist?(manifest_path)).to be false
    end
  end

  describe 'atomic writes' do
    let(:temp_dir) { Dir.mktmpdir }
    let(:file_path) { File.join(temp_dir, 'db/structure.sql') }

    before do
      allow(Rails).to receive(:root).and_return(Pathname.new(temp_dir))
      writer.write_single_file('db/structure.sql', '-- complete previous dump')
    end

    after { FileUtils.rm_rf(temp_dir) }

    it 'leaves the previous file intact and raises when the write cannot complete' do
      allow(File).to receive(:rename).and_raise(Errno::ENOSPC)

      expect { writer.write_single_file('db/structure.sql', '-- new dump') }.to raise_error(Errno::ENOSPC)
      expect(File.read(file_path)).to eq('-- complete previous dump')
    end

    it 'replaces the file content on success' do
      writer.write_single_file('db/structure.sql', '-- new dump')

      expect(File.read(file_path)).to eq('-- new dump')
      expect(Dir.children(File.dirname(file_path))).to eq(['structure.sql'])
    end
  end

  describe '#chunk_section (private)' do
    it 'counts the blank separator lines so written files stay within the limit' do
      objects = Array.new(600) { |i| "CREATE INDEX i#{i} ON t (c#{i});" }

      chunks = writer.send(:chunk_section, objects, 500)

      written_line_counts = chunks.map { |chunk| chunk.join("\n\n").lines.count }
      expect(written_line_counts.max).to be <= 550
      expect(chunks.flatten).to eq(objects)
    end

    it 'keeps an object of exactly max lines in a file of its own without splitting it' do
      exact = (['line'] * 500).join("\n")
      chunks = writer.send(:chunk_section, [exact, 'SELECT 2;'], 500)

      expect(chunks).to eq([[exact], ['SELECT 2;']])
    end

    it 'returns no chunks for an empty section' do
      expect(writer.send(:chunk_section, [], 500)).to eq([])
    end

    it 'creates single chunk when under limit' do
      objects = ['CREATE TABLE t1 (id bigint);']
      chunks = writer.send(:chunk_section, objects, 500)

      expect(chunks.length).to eq(1)
      expect(chunks.first).to eq(objects)
    end

    it 'splits into multiple chunks when exceeding overflow threshold' do
      # Create objects that will exceed 500 * 1.1 = 550 lines
      object1 = "line\n" * 400 # 400 lines
      object2 = "line\n" * 200 # 200 lines (total 600 > 550)
      objects = [object1, object2]

      chunks = writer.send(:chunk_section, objects, 500)

      expect(chunks.length).to eq(2)
    end

    it 'gives large single object its own file' do
      # Object larger than max_lines gets dedicated file
      large_object = "line\n" * 600
      small_object = "line\n" * 100
      objects = [large_object, small_object]

      chunks = writer.send(:chunk_section, objects, 500)

      expect(chunks.length).to eq(2)
      expect(chunks[0]).to eq([large_object]) # Large object alone
      expect(chunks[1]).to eq([small_object]) # Small object alone
    end

    it 'allows overflow within threshold' do
      # 450 + 80 = 530 lines, which is within 500 * 1.1 = 550
      object1 = "line\n" * 450
      object2 = "line\n" * 80
      objects = [object1, object2]

      chunks = writer.send(:chunk_section, objects, 500)

      expect(chunks.length).to eq(1) # Both fit in one chunk
      expect(chunks.first).to contain_exactly(object1, object2)
    end
  end
end
