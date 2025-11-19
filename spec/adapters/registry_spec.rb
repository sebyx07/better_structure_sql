# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::Adapters::Registry do
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter) }

  before do
    described_class.clear_cache!
    BetterStructureSql.reset_configuration
  end

  after do
    described_class.clear_cache!
  end

  describe '.adapter_for' do
    context 'with auto detection' do
      it 'detects PostgreSQL adapter' do
        allow(connection).to receive(:adapter_name).and_return('PostgreSQL')
        adapter = described_class.adapter_for(connection, adapter_override: :auto)
        expect(adapter).to be_a(BetterStructureSql::Adapters::PostgresqlAdapter)
      end

      it 'detects PostGIS as PostgreSQL' do
        allow(connection).to receive(:adapter_name).and_return('PostGIS')
        adapter = described_class.adapter_for(connection, adapter_override: :auto)
        expect(adapter).to be_a(BetterStructureSql::Adapters::PostgresqlAdapter)
      end

      it 'detects MySQL adapter' do
        allow(connection).to receive(:adapter_name).and_return('Mysql2')
        allow(described_class).to receive(:require).with('mysql2').and_return(true)
        adapter = described_class.adapter_for(connection, adapter_override: :auto)
        expect(adapter).to be_a(BetterStructureSql::Adapters::MysqlAdapter)
      end

      it 'detects SQLite adapter' do
        allow(connection).to receive(:adapter_name).and_return('SQLite3')
        allow(described_class).to receive(:require).with('sqlite3').and_return(true)
        adapter = described_class.adapter_for(connection, adapter_override: :auto)
        expect(adapter).to be_a(BetterStructureSql::Adapters::SqliteAdapter)
      end

      it 'raises error for unsupported adapter' do
        allow(connection).to receive(:adapter_name).and_return('Oracle')
        expect do
          described_class.adapter_for(connection, adapter_override: :auto)
        end.to raise_error(BetterStructureSql::Error, /Unsupported database adapter/)
      end
    end

    context 'with manual override' do
      it 'uses PostgreSQL adapter when specified' do
        adapter = described_class.adapter_for(connection, adapter_override: :postgresql)
        expect(adapter).to be_a(BetterStructureSql::Adapters::PostgresqlAdapter)
      end

      it 'raises error for invalid adapter override' do
        expect do
          described_class.adapter_for(connection, adapter_override: :invalid)
        end.to raise_error(BetterStructureSql::Error, /Invalid adapter override/)
      end
    end

    context 'caching' do
      it 'returns same adapter instance for same connection' do
        allow(connection).to receive(:adapter_name).and_return('PostgreSQL')
        adapter1 = described_class.adapter_for(connection, adapter_override: :auto)
        adapter2 = described_class.adapter_for(connection, adapter_override: :auto)
        expect(adapter1.object_id).to eq(adapter2.object_id)
      end

      it 'returns different adapter for different override' do
        allow(connection).to receive(:adapter_name).and_return('PostgreSQL')
        adapter1 = described_class.adapter_for(connection, adapter_override: :postgresql)
        adapter2 = described_class.adapter_for(connection, adapter_override: :auto)
        expect(adapter1.object_id).not_to eq(adapter2.object_id)
      end
    end
  end

  describe '.clear_cache!' do
    it 'clears the adapter cache' do
      allow(connection).to receive(:adapter_name).and_return('PostgreSQL')
      adapter1 = described_class.adapter_for(connection, adapter_override: :auto)
      described_class.clear_cache!
      adapter2 = described_class.adapter_for(connection, adapter_override: :auto)
      expect(adapter1.object_id).not_to eq(adapter2.object_id)
    end
  end
end
