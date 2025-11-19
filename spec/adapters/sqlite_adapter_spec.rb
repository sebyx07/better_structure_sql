# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/better_structure_sql/adapters/sqlite_adapter'

RSpec.describe BetterStructureSql::Adapters::SqliteAdapter do
  let(:connection) { double('ActiveRecord::Connection') }
  let(:adapter) { described_class.new(connection) }

  describe '#fetch_extensions' do
    it 'returns empty array (SQLite does not support extensions)' do
      expect(adapter.fetch_extensions(connection)).to eq([])
    end
  end

  describe '#fetch_custom_types' do
    it 'returns empty array (SQLite does not have custom types)' do
      expect(adapter.fetch_custom_types(connection)).to eq([])
    end
  end

  describe '#fetch_tables' do
    it 'fetches tables using sqlite_master' do
      query_result = [
        ['users', 'CREATE TABLE users (id INTEGER PRIMARY KEY)'],
        ['posts', 'CREATE TABLE posts (id INTEGER PRIMARY KEY)']
      ]

      allow(connection).to receive(:execute).and_return(query_result)
      allow(connection).to receive(:quote).and_return("'users'", "'posts'")
      allow(adapter).to receive(:fetch_columns).and_return([])
      allow(adapter).to receive(:fetch_primary_key).and_return([])
      allow(adapter).to receive(:fetch_constraints).and_return([])

      tables = adapter.fetch_tables(connection)

      expect(tables.length).to eq(2)
      expect(tables.first[:name]).to eq('users')
      expect(tables.last[:name]).to eq('posts')
    end
  end

  describe '#fetch_indexes' do
    it 'fetches indexes using PRAGMA index_list and index_info' do
      table_names = ['users']

      # Mock table names query
      allow(adapter).to receive(:fetch_table_names).and_return(table_names)

      # Mock PRAGMA index_list
      index_list_result = [
        [0, 'idx_email', 1, 'c', 0] # seq, name, unique, origin, partial
      ]

      # Mock PRAGMA index_info
      index_info_result = [
        [0, 0, 'email'] # seqno, cid, name
      ]

      allow(connection).to receive(:quote).and_return("'users'", "'idx_email'")
      allow(connection).to receive(:execute)
        .with(/PRAGMA index_list/).and_return(index_list_result)
      allow(connection).to receive(:execute)
        .with(/PRAGMA index_info/).and_return(index_info_result)

      indexes = adapter.fetch_indexes(connection)

      expect(indexes.length).to eq(1)
      expect(indexes.first[:name]).to eq('idx_email')
      expect(indexes.first[:columns]).to eq(['email'])
      expect(indexes.first[:unique]).to be true
    end

    it 'skips auto-generated indexes for PRIMARY KEY and UNIQUE' do
      table_names = ['users']
      allow(adapter).to receive(:fetch_table_names).and_return(table_names)

      # Mock indexes with pk and u origins
      index_list_result = [
        [0, 'sqlite_autoindex_users_1', 1, 'pk', 0],
        [1, 'sqlite_autoindex_users_2', 1, 'u', 0]
      ]

      allow(connection).to receive(:quote).and_return("'users'")
      allow(connection).to receive(:execute)
        .with(/PRAGMA index_list/).and_return(index_list_result)

      indexes = adapter.fetch_indexes(connection)

      expect(indexes).to be_empty
    end
  end

  describe '#fetch_foreign_keys' do
    it 'fetches foreign keys using PRAGMA foreign_key_list' do
      table_names = ['posts']
      allow(adapter).to receive(:fetch_table_names).and_return(table_names)

      # PRAGMA foreign_key_list returns: id, seq, table, from, to, on_update, on_delete, match
      fk_list_result = [
        [0, 0, 'users', 'user_id', 'id', 'CASCADE', 'CASCADE', 'NONE']
      ]

      allow(connection).to receive(:quote).and_return("'posts'")
      allow(connection).to receive(:execute)
        .with(/PRAGMA foreign_key_list/).and_return(fk_list_result)

      foreign_keys = adapter.fetch_foreign_keys(connection)

      expect(foreign_keys.length).to eq(1)
      expect(foreign_keys.first[:table]).to eq('posts')
      expect(foreign_keys.first[:column]).to eq('user_id')
      expect(foreign_keys.first[:foreign_table]).to eq('users')
      expect(foreign_keys.first[:foreign_column]).to eq('id')
      expect(foreign_keys.first[:on_delete]).to eq('CASCADE')
    end
  end

  describe '#fetch_views' do
    it 'fetches views using sqlite_master' do
      query_result = [
        ['user_stats', 'CREATE VIEW user_stats AS SELECT * FROM users']
      ]

      allow(connection).to receive(:execute).and_return(query_result)

      views = adapter.fetch_views(connection)

      expect(views.length).to eq(1)
      expect(views.first[:name]).to eq('user_stats')
      expect(views.first[:definition]).to include('SELECT * FROM users')
    end
  end

  describe '#fetch_materialized_views' do
    it 'returns empty array (SQLite does not support materialized views)' do
      expect(adapter.fetch_materialized_views(connection)).to eq([])
    end
  end

  describe '#fetch_functions' do
    it 'returns empty array (SQLite does not support stored procedures/functions)' do
      expect(adapter.fetch_functions(connection)).to eq([])
    end
  end

  describe '#fetch_sequences' do
    it 'returns empty array (SQLite uses AUTOINCREMENT)' do
      expect(adapter.fetch_sequences(connection)).to eq([])
    end
  end

  describe '#fetch_triggers' do
    it 'fetches triggers using sqlite_master' do
      query_result = [
        ['update_timestamp', 'posts', 'CREATE TRIGGER update_timestamp AFTER INSERT ON posts BEGIN...END']
      ]

      allow(connection).to receive(:execute).and_return(query_result)

      triggers = adapter.fetch_triggers(connection)

      expect(triggers.length).to eq(1)
      expect(triggers.first[:name]).to eq('update_timestamp')
      expect(triggers.first[:table_name]).to eq('posts')
    end

    it 'parses timing and event from SQL' do
      query_result = [
        ['before_delete', 'users', 'CREATE TRIGGER before_delete BEFORE DELETE ON users BEGIN...END']
      ]

      allow(connection).to receive(:execute).and_return(query_result)

      triggers = adapter.fetch_triggers(connection)

      expect(triggers.first[:timing]).to eq('BEFORE')
      expect(triggers.first[:event]).to eq('DELETE')
    end
  end

  describe 'capability methods' do
    it 'returns false for unsupported features' do
      expect(adapter.supports_extensions?).to be false
      expect(adapter.supports_materialized_views?).to be false
      expect(adapter.supports_custom_types?).to be false
      expect(adapter.supports_domains?).to be false
      expect(adapter.supports_functions?).to be false
      expect(adapter.supports_sequences?).to be false
    end

    it 'returns true for supported features' do
      expect(adapter.supports_triggers?).to be true
      expect(adapter.supports_check_constraints?).to be true
    end
  end

  describe '#database_version' do
    it 'detects SQLite version' do
      allow(connection).to receive(:select_value).and_return('3.45.1')

      expect(adapter.database_version).to eq('3.45.1')
    end
  end

  describe '#parse_version' do
    it 'parses SQLite version string' do
      expect(adapter.parse_version('3.45.1')).to eq('3.45.1')
      expect(adapter.parse_version('3.37.0')).to eq('3.37.0')
    end

    it 'returns unknown for invalid version' do
      expect(adapter.parse_version('invalid')).to eq('unknown')
    end
  end

  describe '#resolve_column_type' do
    it 'normalizes integer types' do
      expect(adapter.send(:resolve_column_type, 'INTEGER')).to eq('integer')
      expect(adapter.send(:resolve_column_type, 'INT')).to eq('integer')
    end

    it 'normalizes text types' do
      expect(adapter.send(:resolve_column_type, 'VARCHAR(255)')).to eq('text')
      expect(adapter.send(:resolve_column_type, 'CHAR(10)')).to eq('text')
      expect(adapter.send(:resolve_column_type, 'TEXT')).to eq('text')
    end

    it 'normalizes real types' do
      expect(adapter.send(:resolve_column_type, 'REAL')).to eq('real')
      expect(adapter.send(:resolve_column_type, 'FLOAT')).to eq('real')
      expect(adapter.send(:resolve_column_type, 'DOUBLE')).to eq('real')
    end

    it 'keeps blob type' do
      expect(adapter.send(:resolve_column_type, 'BLOB')).to eq('blob')
    end

    it 'recognizes boolean' do
      expect(adapter.send(:resolve_column_type, 'BOOLEAN')).to eq('boolean')
    end
  end
end
