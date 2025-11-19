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

  describe 'SQL generation methods' do
    describe '#generate_table' do
      it 'returns original SQL from sqlite_master if available' do
        table = {
          name: 'users',
          sql: 'CREATE TABLE users (id INTEGER PRIMARY KEY)'
        }

        expect(adapter.generate_table(table)).to eq('CREATE TABLE users (id INTEGER PRIMARY KEY)')
      end

      it 'generates CREATE TABLE from columns' do
        table = {
          name: 'users',
          columns: [
            { name: 'id', type: 'integer', nullable: false, primary_key: true },
            { name: 'email', type: 'text', nullable: false }
          ],
          primary_key: ['id']
        }

        sql = adapter.generate_table(table)
        expect(sql).to include('CREATE TABLE "users"')
        expect(sql).to include('"id" INTEGER')
        expect(sql).to include('PRIMARY KEY')
        expect(sql).to include('"email" TEXT NOT NULL')
      end
    end

    describe '#generate_index' do
      it 'generates CREATE INDEX statement' do
        index = {
          name: 'idx_email',
          table: 'users',
          columns: ['email'],
          unique: false
        }

        sql = adapter.generate_index(index)
        expect(sql).to eq('CREATE INDEX "idx_email" ON "users" ("email");')
      end

      it 'generates CREATE UNIQUE INDEX statement' do
        index = {
          name: 'idx_email',
          table: 'users',
          columns: ['email'],
          unique: true
        }

        sql = adapter.generate_index(index)
        expect(sql).to eq('CREATE UNIQUE INDEX "idx_email" ON "users" ("email");')
      end

      it 'handles multi-column indexes' do
        index = {
          name: 'idx_name_email',
          table: 'users',
          columns: ['name', 'email'],
          unique: false
        }

        sql = adapter.generate_index(index)
        expect(sql).to include('"name", "email"')
      end
    end

    describe '#generate_foreign_key' do
      it 'generates inline foreign key constraint' do
        fk = {
          column: 'user_id',
          foreign_table: 'users',
          foreign_column: 'id',
          on_delete: 'CASCADE',
          on_update: 'NO ACTION'
        }

        sql = adapter.generate_foreign_key(fk)
        expect(sql).to include('FOREIGN KEY ("user_id")')
        expect(sql).to include('REFERENCES "users"("id")')
        expect(sql).to include('ON DELETE CASCADE')
        expect(sql).to include('ON UPDATE NO ACTION')
      end
    end

    describe '#generate_view' do
      it 'returns original SQL if it starts with CREATE VIEW' do
        view = {
          name: 'user_stats',
          definition: 'CREATE VIEW user_stats AS SELECT * FROM users'
        }

        expect(adapter.generate_view(view)).to eq('CREATE VIEW user_stats AS SELECT * FROM users')
      end

      it 'generates CREATE VIEW from definition' do
        view = {
          name: 'user_stats',
          definition: 'SELECT * FROM users'
        }

        sql = adapter.generate_view(view)
        expect(sql).to include('CREATE VIEW "user_stats" AS')
        expect(sql).to include('SELECT * FROM users')
      end
    end

    describe '#generate_trigger' do
      it 'returns original SQL if it starts with CREATE TRIGGER' do
        trigger = {
          name: 'update_timestamp',
          statement: 'CREATE TRIGGER update_timestamp AFTER INSERT ON posts BEGIN...END'
        }

        expect(adapter.generate_trigger(trigger)).to eq('CREATE TRIGGER update_timestamp AFTER INSERT ON posts BEGIN...END')
      end

      it 'generates CREATE TRIGGER from components' do
        trigger = {
          name: 'update_timestamp',
          timing: 'AFTER',
          event: 'UPDATE',
          table_name: 'posts',
          body: 'UPDATE posts SET updated_at = datetime(\'now\') WHERE id = NEW.id;'
        }

        sql = adapter.generate_trigger(trigger)
        expect(sql).to include('CREATE TRIGGER "update_timestamp"')
        expect(sql).to include('AFTER UPDATE ON "posts"')
        expect(sql).to include('BEGIN')
        expect(sql).to include('END;')
      end
    end

    describe '#quote_identifier' do
      it 'quotes identifiers with double quotes' do
        expect(adapter.send(:quote_identifier, 'table_name')).to eq('"table_name"')
      end
    end

    describe '#format_default_value' do
      it 'formats NULL' do
        expect(adapter.send(:format_default_value, nil)).to eq('NULL')
      end

      it 'formats strings with quotes' do
        expect(adapter.send(:format_default_value, 'test')).to eq("'test'")
      end

      it 'handles function calls without quotes' do
        expect(adapter.send(:format_default_value, 'CURRENT_TIMESTAMP')).to eq('CURRENT_TIMESTAMP')
      end

      it 'formats booleans as 1/0' do
        expect(adapter.send(:format_default_value, true)).to eq('1')
        expect(adapter.send(:format_default_value, false)).to eq('0')
      end
    end
  end
end
