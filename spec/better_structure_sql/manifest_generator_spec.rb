# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BetterStructureSql::ManifestGenerator do
  let(:config)    { BetterStructureSql::Configuration.new }
  let(:generator) { described_class.new(config) }

  describe '#generate' do
    let(:file_map) do
      {
        '1_extensions/000001.sql' => "CREATE EXTENSION pgcrypto;\nCREATE EXTENSION \"uuid-ossp\";",
        '2_types/000001.sql' => "CREATE TYPE status AS ENUM ('active', 'inactive');",
        '5_tables/000001.sql' => "CREATE TABLE users (id bigint);\n\nCREATE TABLE posts (id bigint);",
        '5_tables/000002.sql' => 'CREATE TABLE comments (id bigint);'
      }
    end

    it 'returns valid JSON' do
      result = generator.generate(file_map)

      expect { JSON.parse(result) }.not_to raise_error
    end

    it 'includes version' do
      result = generator.generate(file_map)
      data = JSON.parse(result)

      expect(data['version']).to eq('1.0')
    end

    it 'calculates total file count' do
      result = generator.generate(file_map)
      data = JSON.parse(result)

      expect(data['total_files']).to eq(4)
    end

    it 'calculates total line count' do
      result = generator.generate(file_map)
      data = JSON.parse(result)

      # 2 + 1 + 3 + 1 = 7 lines
      expect(data['total_lines']).to eq(7)
    end

    it 'includes max_lines_per_file from config' do
      config.max_lines_per_file = 600
      result = generator.generate(file_map)
      data = JSON.parse(result)

      expect(data['max_lines_per_file']).to eq(600)
    end

    it 'calculates directory statistics' do
      result = generator.generate(file_map)
      data = JSON.parse(result)

      expect(data['directories']).to be_a(Hash)
      expect(data['directories']['1_extensions']).to eq({ 'files' => 1, 'lines' => 2 })
      expect(data['directories']['2_types']).to eq({ 'files' => 1, 'lines' => 1 })
      expect(data['directories']['5_tables']).to eq({ 'files' => 2, 'lines' => 4 })
    end

    it 'sorts directories by name' do
      result = generator.generate(file_map)
      data = JSON.parse(result)

      directory_names = data['directories'].keys
      expect(directory_names).to eq(directory_names.sort)
    end
  end

  describe '#parse' do
    let(:manifest_json) do
      {
        version: '1.0',
        generated_at: '2025-01-01T12:00:00Z',
        total_files: 10,
        directories: { '1_extensions' => { 'files' => 1, 'lines' => 5 } }
      }.to_json
    end

    it 'parses JSON string into hash' do
      result = generator.parse(manifest_json)

      expect(result).to be_a(Hash)
      expect(result[:version]).to eq('1.0')
    end

    it 'symbolizes keys' do
      result = generator.parse(manifest_json)

      expect(result.keys.first).to be_a(Symbol)
    end
  end
end
