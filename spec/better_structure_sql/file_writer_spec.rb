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

      expect(Dir.exist?(File.join(temp_dir, base_path, '1_extensions'))).to be true
      expect(Dir.exist?(File.join(temp_dir, base_path, '2_types'))).to be true
      expect(Dir.exist?(File.join(temp_dir, base_path, '5_tables'))).to be true
    end

    it 'writes header file' do
      writer.write_multi_file(base_path, sections, header)

      header_content = File.read(File.join(temp_dir, base_path, '_header.sql'))
      expect(header_content).to eq(header)
    end

    it 'writes numbered SQL files' do
      writer.write_multi_file(base_path, sections, header)

      expect(File.exist?(File.join(temp_dir, base_path, '1_extensions', '000001.sql'))).to be true
      expect(File.exist?(File.join(temp_dir, base_path, '2_types', '000001.sql'))).to be true
      expect(File.exist?(File.join(temp_dir, base_path, '5_tables', '000001.sql'))).to be true
    end

    it 'returns file map for manifest' do
      file_map = writer.write_multi_file(base_path, sections, header)

      expect(file_map).to be_a(Hash)
      expect(file_map.keys).to include('1_extensions/000001.sql')
      expect(file_map.keys).to include('2_types/000001.sql')
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
      tables_dir = File.join(temp_dir, base_path, '5_tables')
      files = Dir.glob(File.join(tables_dir, '*.sql')).sort
      expect(files.length).to be >= 2
    end
  end

  describe '#chunk_section (private)' do
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
