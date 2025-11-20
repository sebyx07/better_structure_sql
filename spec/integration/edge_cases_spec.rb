# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Edge Cases' do
  let(:config)     { BetterStructureSql::Configuration.new }
  let(:connection) { ActiveRecord::Base.connection }
  let(:adapter)    { BetterStructureSql::Adapters::Registry.adapter_for(connection) }

  describe 'Empty database' do
    it 'handles database with no tables' do
      # Fetch with empty database
      tables = adapter.fetch_tables(connection)

      # May have schema_migrations, ar_internal_metadata, better_structure_sql_schema_versions
      # Just verify it doesn't crash
      expect(tables).to be_an(Array)
    end

    it 'handles database with no indexes' do
      indexes = adapter.fetch_indexes(connection)
      expect(indexes).to be_an(Array)
    end

    it 'handles database with no views' do
      views = adapter.fetch_views(connection)
      expect(views).to be_an(Array)
    end
  end

  describe 'Reserved SQL keywords' do
    before do
      skip 'Reserved keyword testing requires manual setup'
    end

    it 'handles table named with reserved keyword' do
      # Would need to create table named 'select', 'where', etc.
      # Skip for now as it requires special setup
    end

    it 'handles column named with reserved keyword' do
      # Would need to create column named 'key', 'value', etc.
      # Already tested in integration via ar_internal_metadata.key column
    end
  end

  describe 'Unicode identifiers' do
    before do
      skip 'Unicode identifier testing requires manual setup'
    end

    it 'handles tables with Unicode names' do
      # Would need database that supports Unicode table names
    end

    it 'handles columns with Unicode names' do
      # Would need database that supports Unicode column names
    end
  end

  describe 'Very long identifiers' do
    before do
      skip 'Long identifier testing requires manual setup'
    end

    it 'handles identifiers at PostgreSQL 63 character limit' do
      # Would test truncation/handling of max length identifiers
    end
  end

  describe 'Configuration edge cases' do
    it 'rejects blank output_path' do
      config.output_path = ''
      expect { config.validate! }.to raise_error(BetterStructureSql::ConfigurationError, /cannot be blank/)
    end

    it 'rejects negative schema_versions_limit' do
      config.schema_versions_limit = -1
      expect { config.validate! }.to raise_error(BetterStructureSql::ConfigurationError, /non-negative integer/)
    end

    it 'accepts zero schema_versions_limit (unlimited)' do
      config.schema_versions_limit = 0
      expect { config.validate! }.not_to raise_error
    end

    it 'rejects overflow_threshold less than 1.0' do
      config.overflow_threshold = 0.9
      expect { config.validate! }.to raise_error(BetterStructureSql::ConfigurationError, /must be >= 1.0/)
    end
  end
end
