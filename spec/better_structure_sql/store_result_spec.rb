# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::StoreResult do
  describe '#skipped?' do
    it 'returns true when skipped' do
      result = described_class.new(skipped: true, version_id: 5, hash: 'abc123', total_count: 10)

      expect(result.skipped?).to be true
      expect(result.stored?).to be false
    end

    it 'returns false when stored' do
      version = double('SchemaVersion', id: 3, content_hash: 'abc123')
      result = described_class.new(skipped: false, version: version)

      expect(result.skipped?).to be false
      expect(result.stored?).to be true
    end
  end

  describe '#stored?' do
    it 'returns true when stored' do
      version = double('SchemaVersion', id: 7, content_hash: 'abc123')
      result = described_class.new(skipped: false, version: version, total_count: 15)

      expect(result.stored?).to be true
      expect(result.skipped?).to be false
    end

    it 'returns false when skipped' do
      result = described_class.new(skipped: true, version_id: 10, hash: 'def456', total_count: 20)

      expect(result.stored?).to be false
      expect(result.skipped?).to be true
    end
  end

  describe 'attributes' do
    context 'when skipped' do
      it 'provides version_id and hash' do
        result = described_class.new(
          skipped: true,
          version_id: 10,
          hash: 'def456',
          total_count: 5
        )

        expect(result.version_id).to eq(10)
        expect(result.hash).to eq('def456')
        expect(result.total_count).to eq(5)
        expect(result.version).to be_nil
      end

      it 'handles nil version gracefully' do
        result = described_class.new(
          skipped: true,
          version: nil,
          total_count: 0
        )

        expect(result.version_id).to be_nil
        expect(result.hash).to be_nil
        expect(result.total_count).to eq(0)
      end
    end

    context 'when stored' do
      it 'provides version and derives version_id and hash' do
        version = double('SchemaVersion', id: 15, content_hash: '123abc456def')
        result = described_class.new(
          skipped: false,
          version: version,
          total_count: 25
        )

        expect(result.version).to eq(version)
        expect(result.version_id).to eq(15)
        expect(result.hash).to eq('123abc456def')
        expect(result.total_count).to eq(25)
      end

      it 'allows explicit version_id to override' do
        version = double('SchemaVersion', id: 20, content_hash: 'abc123')
        result = described_class.new(
          skipped: false,
          version: version,
          version_id: 99,  # Explicit override
          total_count: 30
        )

        # Explicit version_id takes precedence
        expect(result.version_id).to eq(99)
      end
    end
  end

  describe 'initialization' do
    it 'requires skipped parameter' do
      expect do
        described_class.new(version_id: 5)
      end.to raise_error(ArgumentError, /missing keyword.*skipped/)
    end

    it 'accepts all optional parameters' do
      version = double('SchemaVersion', id: 25, content_hash: 'version_hash')
      result = described_class.new(
        skipped: false,
        version: version,
        version_id: 100,
        hash: 'custom_hash',
        total_count: 50
      )

      expect(result).to be_a(described_class)
      expect(result.version).to eq(version)
      expect(result.version_id).to eq(100)
      expect(result.hash).to eq('custom_hash')
      expect(result.total_count).to eq(50)
    end
  end
end
