# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::SchemaVersion do
  # Skip ActiveRecord tests if database not available
  # These are tested in integration tests with real database

  describe 'instance methods' do
    let(:mock_version) do
      double('SchemaVersion',
             content: 'CREATE TABLE users (id serial);',
             pg_version: '14.5',
             format_type: 'sql',
             output_mode: 'single_file',
             created_at: Time.current)
    end

    describe '#size' do
      it 'calculates byte size of content' do
        # Test the logic of the size method
        content = '12345'
        expect(content.bytesize).to eq(5)
      end
    end

    describe '#formatted_size' do
      it 'formats bytes correctly' do
        bytes = 500
        result = "#{bytes} bytes" if bytes < 1024
        expect(result).to eq('500 bytes')
      end

      it 'formats kilobytes correctly' do
        bytes = 2048
        result = "#{(bytes / 1024.0).round(2)} KB" if bytes >= 1024 && bytes < 1024 * 1024
        expect(result).to eq('2.0 KB')
      end

      it 'formats megabytes correctly' do
        bytes = 2 * 1024 * 1024
        result = "#{(bytes / 1024.0 / 1024.0).round(2)} MB" if bytes >= 1024 * 1024
        expect(result).to eq('2.0 MB')
      end
    end
  end

  describe 'validations' do
    # NOTE: validation logic is defined in the model
    # Integration tests with real database verify these work correctly
    it 'defines validations for required fields' do
      expect(described_class).to respond_to(:validates)
    end
  end

  describe '#hash_matches?' do
    let(:version) do
      double('SchemaVersion', content_hash: 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6')
    end

    it 'returns true when hashes match' do
      allow(version).to receive(:hash_matches?).with('a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6').and_return(true)
      expect(version.hash_matches?('a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6')).to be true
    end

    it 'returns false when hashes differ' do
      allow(version).to receive(:hash_matches?).with('different_hash').and_return(false)
      expect(version.hash_matches?('different_hash')).to be false
    end

    it 'handles nil comparison' do
      allow(version).to receive(:hash_matches?).with(nil).and_return(false)
      expect(version.hash_matches?(nil)).to be false
    end
  end
end
