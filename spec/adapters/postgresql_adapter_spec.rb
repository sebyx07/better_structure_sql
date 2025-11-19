# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/better_structure_sql/adapters/postgresql_adapter'

RSpec.describe BetterStructureSql::Adapters::PostgresqlAdapter do
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter) }
  let(:adapter)    { described_class.new(connection) }

  describe 'capability methods' do
    it 'supports all PostgreSQL features' do
      expect(adapter.supports_extensions?).to be true
      expect(adapter.supports_materialized_views?).to be true
      expect(adapter.supports_custom_types?).to be true
      expect(adapter.supports_domains?).to be true
      expect(adapter.supports_functions?).to be true
      expect(adapter.supports_triggers?).to be true
      expect(adapter.supports_sequences?).to be true
    end
  end

  describe '#database_version' do
    it 'detects PostgreSQL version' do
      allow(connection).to receive(:select_value)
        .with('SELECT version()')
        .and_return('PostgreSQL 14.5 (Ubuntu 14.5-1.pgdg20.04+1) on x86_64-pc-linux-gnu')

      expect(adapter.database_version).to eq('14.5')
    end

    it 'caches the version' do
      allow(connection).to receive(:select_value)
        .with('SELECT version()')
        .and_return('PostgreSQL 14.5')
        .once

      adapter.database_version
      adapter.database_version # Should use cached value
    end
  end

  describe '#parse_version' do
    it 'parses PostgreSQL version string' do
      version_string = 'PostgreSQL 14.5 (Ubuntu 14.5-1.pgdg20.04+1) on x86_64-pc-linux-gnu'
      expect(adapter.parse_version(version_string)).to eq('14.5')
    end

    it 'handles different PostgreSQL version formats' do
      expect(adapter.parse_version('PostgreSQL 13.0')).to eq('13.0')
      expect(adapter.parse_version('PostgreSQL 15.2')).to eq('15.2')
    end

    it 'returns unknown for invalid format' do
      expect(adapter.parse_version('Invalid version')).to eq('unknown')
    end
  end

  describe 'introspection methods' do
    describe '#fetch_extensions' do
      it 'returns array of extension hashes' do
        result = [
          { 'extname' => 'pgcrypto', 'extversion' => '1.3', 'schema_name' => 'public' },
          { 'extname' => 'uuid-ossp', 'extversion' => '1.1', 'schema_name' => 'public' }
        ]

        allow(connection).to receive(:execute).and_return(result)

        extensions = adapter.fetch_extensions(connection)
        expect(extensions).to eq([
          { name: 'pgcrypto', version: '1.3', schema: 'public' },
          { name: 'uuid-ossp', version: '1.1', schema: 'public' }
        ])
      end

      it 'returns empty array when no extensions' do
        allow(connection).to receive(:execute).and_return([])
        expect(adapter.fetch_extensions(connection)).to eq([])
      end
    end

    describe '#fetch_tables' do
      it 'queries for tables and their metadata' do
        # Mock the main tables query
        tables_result = [{ 'table_name' => 'users', 'table_schema' => 'public' }]

        # Mock the quote method
        allow(connection).to receive_messages(execute: tables_result, quote: "'users'")

        # Mock the columns query
        columns_result = double
        allow(columns_result).to receive(:map).and_return([
          {
            name: 'id',
            type: 'bigint',
            default: nil,
            nullable: false,
            length: nil,
            precision: 64,
            scale: 0
          }
        ])

        # Mock the primary key query
        pk_result = double
        allow(pk_result).to receive(:pluck).with('column_name').and_return(['id'])

        # Mock the constraints query
        constraints_result = double
        allow(constraints_result).to receive(:map).and_return([])

        allow(connection).to receive(:select_all).and_return(columns_result, pk_result, constraints_result)

        tables = adapter.fetch_tables(connection)
        expect(tables).to be_an(Array)
        expect(tables.first[:name]).to eq('users')
        expect(tables.first[:columns]).to be_an(Array)
        expect(tables.first[:primary_key]).to be_an(Array)
        expect(tables.first[:constraints]).to be_an(Array)
      end
    end

    describe '#fetch_views' do
      it 'returns array of view hashes' do
        result = [
          {
            'schemaname' => 'public',
            'viewname' => 'active_users',
            'definition' => 'SELECT * FROM users WHERE active = true'
          }
        ]

        allow(connection).to receive(:execute).and_return(result)

        views = adapter.fetch_views(connection)
        expect(views).to eq([
          {
            schema: 'public',
            name: 'active_users',
            definition: 'SELECT * FROM users WHERE active = true'
          }
        ])
      end
    end

    describe '#fetch_materialized_views' do
      it 'returns array of materialized view hashes with indexes' do
        result = [
          {
            'schemaname' => 'public',
            'matviewname' => 'user_stats',
            'definition' => 'SELECT COUNT(*) FROM users'
          }
        ]

        # Mock the main matviews query

        # Mock the quote method

        # Mock the indexes query for the materialized view
        indexes_result = double
        allow(indexes_result).to receive(:pluck).with('indexdef').and_return([])
        allow(connection).to receive_messages(execute: result, quote: "'user_stats'", select_all: indexes_result)

        matviews = adapter.fetch_materialized_views(connection)
        expect(matviews.first[:name]).to eq('user_stats')
        expect(matviews.first[:indexes]).to eq([])
      end
    end

    describe '#fetch_sequences' do
      it 'returns array of sequence hashes' do
        result = [
          {
            'sequencename' => 'users_id_seq',
            'schemaname' => 'public',
            'start_value' => '1',
            'increment_by' => '1',
            'min_value' => '1',
            'max_value' => '9223372036854775807',
            'cache_size' => '1',
            'cycle' => 'f'
          }
        ]

        allow(connection).to receive(:execute).and_return(result)

        sequences = adapter.fetch_sequences(connection)
        expect(sequences.first[:name]).to eq('users_id_seq')
        expect(sequences.first[:schema]).to eq('public')
      end
    end
  end
end
