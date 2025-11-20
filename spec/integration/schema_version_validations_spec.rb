# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BetterStructureSql::SchemaVersion, type: :model do
  describe 'content_hash validations' do
    let(:valid_attributes) do
      {
        content: 'CREATE TABLE users (id serial);',
        content_hash: Digest::MD5.hexdigest('CREATE TABLE users (id serial);'),
        pg_version: '15.4',
        format_type: 'sql',
        output_mode: 'single_file'
      }
    end

    describe 'presence validation' do
      it 'is valid with all required attributes including content_hash' do
        version = described_class.new(valid_attributes)
        expect(version).to be_valid
      end

      it 'is invalid without content_hash' do
        version = described_class.new(valid_attributes.except(:content_hash))
        expect(version).not_to be_valid
        expect(version.errors[:content_hash]).to include("can't be blank")
      end
    end

    describe 'format validation' do
      it 'accepts valid 32-character MD5 hex digest' do
        version = described_class.new(valid_attributes.merge(
                                        content_hash: 'a1b2c3d4e5f6789012345678901234ab'
                                      ))
        expect(version).to be_valid
      end

      it 'rejects content_hash with 31 characters' do
        version = described_class.new(valid_attributes.merge(
                                        content_hash: 'a1b2c3d4e5f6789012345678901234a'
                                      ))
        expect(version).not_to be_valid
        expect(version.errors[:content_hash]).to include('must be 32-character MD5 hex digest')
      end

      it 'rejects content_hash with 33 characters' do
        version = described_class.new(valid_attributes.merge(
                                        content_hash: 'a1b2c3d4e5f6789012345678901234abc'
                                      ))
        expect(version).not_to be_valid
        expect(version.errors[:content_hash]).to include('must be 32-character MD5 hex digest')
      end

      it 'rejects content_hash with non-hex characters (uppercase)' do
        version = described_class.new(valid_attributes.merge(
                                        content_hash: 'A1B2C3D4E5F6789012345678901234AB'
                                      ))
        expect(version).not_to be_valid
        expect(version.errors[:content_hash]).to include('must be 32-character MD5 hex digest')
      end

      it 'rejects content_hash with non-hex characters (letters g-z)' do
        version = described_class.new(valid_attributes.merge(
                                        content_hash: 'g1h2i3j4k5l6789012345678901234mn'
                                      ))
        expect(version).not_to be_valid
        expect(version.errors[:content_hash]).to include('must be 32-character MD5 hex digest')
      end

      it 'rejects content_hash with special characters' do
        version = described_class.new(valid_attributes.merge(
                                        content_hash: 'a1b2c3d4-e5f6-7890-1234-5678901234ab'
                                      ))
        expect(version).not_to be_valid
        expect(version.errors[:content_hash]).to include('must be 32-character MD5 hex digest')
      end

      it 'rejects content_hash with spaces' do
        version = described_class.new(valid_attributes.merge(
                                        content_hash: 'a1b2c3d4 e5f6 7890 1234 5678901234ab'
                                      ))
        expect(version).not_to be_valid
        expect(version.errors[:content_hash]).to include('must be 32-character MD5 hex digest')
      end
    end

    describe 'edge cases' do
      it 'accepts hash of empty string' do
        empty_hash = Digest::MD5.hexdigest('')
        version = described_class.new(valid_attributes.merge(
                                        content: '',
                                        content_hash: empty_hash
                                      ))
        expect(version.content_hash).to eq('d41d8cd98f00b204e9800998ecf8427e')
        # NOTE: Will fail content presence validation, but content_hash format is valid
      end

      it 'calculates correct MD5 hash for content' do
        content = 'CREATE TABLE test (id serial);'
        expected_hash = Digest::MD5.hexdigest(content)
        version = described_class.new(valid_attributes.merge(
                                        content: content,
                                        content_hash: expected_hash
                                      ))
        expect(version).to be_valid
        expect(version.content_hash).to eq(expected_hash)
      end

      it 'handles large content with correct hash' do
        large_content = 'X' * 1_000_000
        large_hash = Digest::MD5.hexdigest(large_content)
        version = described_class.new(valid_attributes.merge(
                                        content: large_content,
                                        content_hash: large_hash
                                      ))
        expect(version).to be_valid
      end

      it 'handles unicode content with correct hash' do
        unicode_content = 'CREATE TABLE users (name VARCHAR(255) DEFAULT \'José\');'
        unicode_hash = Digest::MD5.hexdigest(unicode_content)
        version = described_class.new(valid_attributes.merge(
                                        content: unicode_content,
                                        content_hash: unicode_hash
                                      ))
        expect(version).to be_valid
      end
    end
  end

  describe '#hash_matches?' do
    let(:version) { create(:schema_version) }

    it 'returns true when hashes match exactly' do
      expect(version.hash_matches?(version.content_hash)).to be true
    end

    it 'returns false when hashes differ' do
      different_hash = 'a1b2c3d4e5f6789012345678901234ab'
      expect(version.hash_matches?(different_hash)).to be false
    end

    it 'returns false when comparing with nil' do
      expect(version.hash_matches?(nil)).to be false
    end

    it 'returns false when comparing with empty string' do
      expect(version.hash_matches?('')).to be false
    end

    it 'is case sensitive' do
      # Assuming version has lowercase hash
      uppercase_hash = version.content_hash.upcase
      expect(version.hash_matches?(uppercase_hash)).to be false
    end
  end

  describe 'factory' do
    it 'creates valid schema version with content_hash' do
      version = create(:schema_version)
      expect(version).to be_valid
      expect(version.content_hash).to be_present
      expect(version.content_hash).to match(/\A[a-f0-9]{32}\z/)
    end

    it 'calculates correct hash for factory content' do
      version = create(:schema_version)
      expected_hash = Digest::MD5.hexdigest(version.content)
      expect(version.content_hash).to eq(expected_hash)
    end

    it 'works with multi_file trait' do
      version = create(:schema_version, :multi_file)
      expect(version).to be_valid
      expect(version.content_hash).to be_present
      expect(version.output_mode).to eq('multi_file')
    end

    it 'works with large trait' do
      version = create(:schema_version, :large)
      expect(version).to be_valid
      expect(version.content_hash).to be_present
      # Hash should be consistent for same content
      expected_hash = Digest::MD5.hexdigest('X' * 1_000_000)
      expect(version.content_hash).to eq(expected_hash)
    end

    it 'works with small trait' do
      version = create(:schema_version, :small)
      expect(version).to be_valid
      expect(version.content_hash).to be_present
      expected_hash = Digest::MD5.hexdigest('Small schema')
      expect(version.content_hash).to eq(expected_hash)
    end
  end
end
