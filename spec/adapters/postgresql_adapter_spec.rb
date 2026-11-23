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
      it 'combines batched columns, constraints and owned sequences' do
        tables_result = [
          { 'oid' => 1, 'table_name' => 'users', 'table_schema' => 'public', 'partition' => false,
            'partition_key' => nil, 'partition_bound' => nil, 'parent_name' => nil }
        ]
        columns_result = [
          { 'table_oid' => 1, 'column_name' => 'id', 'data_type' => 'integer',
            'expression' => "nextval('users_id_seq'::regclass)", 'nullable' => false, 'identity' => '',
            'generated' => '', 'collation' => nil },
          { 'table_oid' => 1, 'column_name' => 'name', 'data_type' => 'character varying(50)[]',
            'expression' => nil, 'nullable' => true, 'identity' => '', 'generated' => '', 'collation' => '"C"' },
          { 'table_oid' => 1, 'column_name' => 'seen_at', 'data_type' => 'timestamp(6) with time zone',
            'expression' => nil, 'nullable' => true, 'identity' => '', 'generated' => '', 'collation' => nil }
        ]
        constraints_result = [
          { 'table_oid' => 1, 'name' => 'users_pkey', 'definition' => 'PRIMARY KEY (id, "a,b")', 'type' => 'p',
            'validated' => true, 'columns' => '["id", "a,b"]' },
          { 'table_oid' => 1, 'name' => 'name_check', 'definition' => 'CHECK (true) NOT VALID', 'type' => 'c',
            'validated' => false, 'columns' => nil }
        ]
        sequences_result = [{ 'table_oid' => 1, 'sequence_name' => 'users_id_seq', 'column_name' => 'id' }]
        allow(connection).to receive(:select_all)
          .and_return(tables_result, columns_result, constraints_result, sequences_result)

        table = adapter.fetch_tables(connection).first

        expect(table).to include(name: 'users', primary_key: ['id', 'a,b'], primary_key_name: 'users_pkey',
                                 owned_sequences: [{ sequence: 'users_id_seq', column: 'id' }], partitions: [])
        expect(table[:columns].pluck(:type)).to eq(%w[integer varchar(50)[] timestamptz(6)])
        expect(table[:columns][1]).to include(collation: '"C"', identity: nil, generated: nil)
        expect(table[:constraints]).to eq([
          { name: 'name_check', definition: 'CHECK (true) NOT VALID', type: :check, validated: false, columns: [] }
        ])
      end

      it 'keeps only the locally defined columns, persistence and storage parameters of an inheritance child' do
        tables_result = [
          { 'oid' => 2, 'table_name' => 'cars', 'table_schema' => 'public', 'partition' => false,
            'unlogged' => true, 'storage_parameters' => 'fillfactor=70', 'inherits' => '["vehicles", "a,b"]' }
        ]
        columns_result = [
          { 'table_oid' => 2, 'column_name' => 'id', 'data_type' => 'integer', 'nullable' => false, 'identity' => '',
            'generated' => '', 'local' => false },
          { 'table_oid' => 2, 'column_name' => 'doors', 'data_type' => 'integer', 'nullable' => true, 'identity' => '',
            'generated' => '', 'local' => true }
        ]
        allow(connection).to receive(:select_all).and_return(tables_result, columns_result, [], [])

        table = adapter.fetch_tables(connection).first

        expect(table).to include(unlogged: true, storage_parameters: 'fillfactor=70', inherits: ['vehicles', 'a,b'])
        expect(table[:columns]).to eq([
          { name: 'doors', type: 'integer', default: nil, nullable: true, collation: nil,
            generated: nil, identity: nil }
        ])
      end

      it 'maps identity and generated columns' do
        tables_result = [{ 'oid' => 1, 'table_name' => 't', 'table_schema' => 'public', 'partition' => false }]
        columns_result = [
          { 'table_oid' => 1, 'column_name' => 'id', 'data_type' => 'bigint', 'expression' => nil,
            'nullable' => false, 'identity' => 'd', 'generated' => '', 'seqstart' => 5, 'seqincrement' => 1,
            'seqmin' => 1, 'seqmax' => 100, 'seqcache' => 1, 'seqcycle' => false },
          { 'table_oid' => 1, 'column_name' => 'total', 'data_type' => 'integer', 'expression' => '(a + b)',
            'nullable' => true, 'identity' => '', 'generated' => 's' }
        ]
        allow(connection).to receive(:select_all).and_return(tables_result, columns_result, [], [])

        id, total = adapter.fetch_tables(connection).first[:columns]

        expect(id[:identity]).to eq(generation: 'BY DEFAULT', start_value: 5, increment: 1, min_value: 1,
                                    max_value: 100, cache_size: 1, cycle: false)
        expect(total).to include(default: nil, generated: { expression: '(a + b)', kind: 'STORED' })
      end

      it 'nests partitions under their parent table' do
        tables_result = [
          { 'oid' => 1, 'table_name' => 'events', 'table_schema' => 'public', 'partition' => false,
            'partition_key' => 'RANGE (day)', 'partition_bound' => nil, 'parent_name' => nil },
          { 'oid' => 2, 'table_name' => 'a_events_2024', 'table_schema' => 'public', 'partition' => true,
            'partition_key' => nil, 'partition_bound' => 'DEFAULT', 'parent_name' => 'events' }
        ]
        allow(connection).to receive(:select_all).and_return(tables_result, [], [], [])

        tables = adapter.fetch_tables(connection)

        expect(tables.pluck(:name)).to eq(['events'])
        expect(tables.first[:partitions].map { |t| t.slice(:name, :partition_of, :partition_bound) })
          .to eq([{ name: 'a_events_2024', partition_of: 'events', partition_bound: 'DEFAULT' }])
      end
    end

    describe '#fetch_views' do
      it 'orders views after the views they select from' do
        views_result = [
          { 'schema_name' => 'public', 'name' => 'a_view', 'definition' => 'SELECT * FROM b_view', 'options' => nil },
          { 'schema_name' => 'public', 'name' => 'b_view', 'definition' => 'SELECT 1', 'options' => 'security_barrier=true' }
        ]
        dependencies_result = [{ 'name' => 'a_view', 'depends_on' => 'b_view' }]
        allow(connection).to receive(:select_all).and_return(views_result, dependencies_result)

        views = adapter.fetch_views(connection)

        expect(views.pluck(:name)).to eq(%w[b_view a_view])
        expect(views.first).to eq(schema: 'public', name: 'b_view', definition: 'SELECT 1', options: 'security_barrier=true')
      end
    end

    describe '#fetch_materialized_views' do
      it 'attaches indexes and comments' do
        indexes_result = [{ 'matview_name' => 'user_stats', 'indexdef' => 'CREATE INDEX i ON public.user_stats USING btree (n)' }]
        comments_result = [{ 'name' => 'user_stats', 'comment' => 'Stats' }]
        matviews_result = [{ 'schema_name' => 'public', 'name' => 'user_stats', 'definition' => 'SELECT 1 AS n' }]
        allow(connection).to receive(:select_all).and_return(indexes_result, comments_result, matviews_result, [])

        matview = adapter.fetch_materialized_views(connection).first

        expect(matview).to include(name: 'user_stats', comment: 'Stats',
                                   indexes: ['CREATE INDEX i ON public.user_stats USING btree (n)'])
      end
    end

    describe '#fetch_indexes' do
      it 'creates indexes of partitioned tables on every partition' do
        result = [
          { 'schemaname' => 'public', 'tablename' => 'events', 'indexname' => 'idx', 'partitioned' => true,
            'indexdef' => 'CREATE INDEX idx ON ONLY public.events USING gin (payload)' }
        ]
        allow(connection).to receive(:select_all).and_return(result)

        expect(adapter.fetch_indexes(connection).first[:definition])
          .to eq('CREATE INDEX idx ON public.events USING gin (payload)')
      end
    end

    describe '#fetch_sequences' do
      it 'returns array of sequence hashes' do
        result = [
          {
            'sequencename' => 'users_id_seq',
            'schemaname' => 'public',
            'data_type' => 'integer',
            'start_value' => '1',
            'increment_by' => '1',
            'min_value' => '1',
            'max_value' => '9223372036854775807',
            'cache_size' => '1',
            'cycle' => 'f'
          }
        ]

        allow(connection).to receive(:select_all).and_return(result)

        sequences = adapter.fetch_sequences(connection)
        expect(sequences.first[:name]).to eq('users_id_seq')
        expect(sequences.first[:schema]).to eq('public')
        expect(sequences.first[:data_type]).to eq('integer')
      end
    end
  end
end
