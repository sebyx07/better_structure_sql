# frozen_string_literal: true

require 'spec_helper'
require 'active_record/connection_adapters/sqlite3_adapter'
require_relative '../../lib/better_structure_sql/adapters/sqlite_adapter'

RSpec.describe BetterStructureSql::Adapters::SqliteAdapter do
  let(:connection) { double('ActiveRecord::Connection') }
  let(:adapter)    { described_class.new(connection) }

  # Introspection runs against a real in-memory database: PRAGMA output
  # (ordering, hidden columns, expression index parts) is what has to be right.
  context 'with a real SQLite database' do
    let(:connection) { ActiveRecord::ConnectionAdapters::SQLite3Adapter.new(adapter: 'sqlite3', database: ':memory:') }

    after { connection.disconnect! }

    def create_schema(sql)
      connection.raw_connection.execute_batch(sql)
    end

    describe '#fetch_extensions' do
      it 'returns only persistent PRAGMAs with non-default values' do
        create_schema('PRAGMA user_version = 7;')

        expect(adapter.fetch_extensions(connection)).to eq(
          [{ name: 'user_version', value: 7, sql: 'PRAGMA user_version = 7;' }]
        )
      end

      it 'omits connection-scoped settings such as journal_mode and cache_size' do
        expect(adapter.fetch_extensions(connection)).to eq([])
      end
    end

    describe '#fetch_tables' do
      before do
        create_schema(<<~SQL)
          CREATE TABLE regions (code TEXT, country TEXT, PRIMARY KEY (country, code)) WITHOUT ROWID;
          CREATE TABLE "ledger entries" (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            label varchar(20) COLLATE NOCASE DEFAULT 'it''s, (here)',
            amount INTEGER NOT NULL,
            total INTEGER GENERATED ALWAYS AS (amount * (1 + 1)) STORED,
            shout TEXT AS (upper(label)),
            CONSTRAINT chk_amount CHECK (amount > (0 - 100)),
            CHECK (length(label) > 1)
          );
        SQL
      end

      let(:tables) { adapter.fetch_tables(connection) }
      let(:ledger) { tables.find { |table| table[:name] == 'ledger entries' } }

      it 'keeps the original CREATE TABLE statement' do
        expect(tables.find { |table| table[:name] == 'regions' }[:sql])
          .to eq('CREATE TABLE regions (code TEXT, country TEXT, PRIMARY KEY (country, code)) WITHOUT ROWID')
      end

      it "includes Rails' schema_migrations table but not SQLite's own tables" do
        connection.execute('CREATE TABLE "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY)')

        expect(tables.pluck(:name)).to eq(['ledger entries', 'regions', 'schema_migrations'])
      end

      it 'returns every column of a composite primary key in key order' do
        expect(tables.find { |table| table[:name] == 'regions' }[:primary_key]).to eq(%w[country code])
      end

      it 'keeps declared column types verbatim' do
        expect(ledger[:columns].find { |column| column[:name] == 'label' }[:type]).to eq('varchar(20)')
      end

      it 'includes generated columns with their expression' do
        generated = ledger[:columns].to_h { |column| [column[:name], column[:generated]] }

        expect(generated).to eq(
          'id' => nil, 'label' => nil, 'amount' => nil,
          'total' => { expression: 'amount * (1 + 1)', kind: 'STORED' },
          'shout' => { expression: 'upper(label)', kind: 'VIRTUAL' }
        )
      end

      it 'returns named CHECK constraints with nested parentheses intact' do
        expect(ledger[:constraints]).to eq(
          [{ name: 'chk_amount', definition: 'CHECK (amount > (0 - 100))', type: :check }]
        )
      end
    end

    describe '#fetch_indexes' do
      before do
        create_schema(<<~SQL)
          CREATE TABLE users (id INTEGER PRIMARY KEY, email TEXT UNIQUE, score INTEGER);
          CREATE INDEX idx_users_score ON users (score) WHERE score > 0;
          CREATE UNIQUE INDEX idx_users_lower_email ON users (lower(email), score DESC);
        SQL
      end

      it 'returns explicit indexes with their original definitions, sorted by name' do
        expect(adapter.fetch_indexes(connection)).to eq(
          [
            { table: 'users', name: 'idx_users_lower_email', columns: ['score'], unique: true, type: 'BTREE',
              definition: 'CREATE UNIQUE INDEX idx_users_lower_email ON users (lower(email), score DESC)' },
            { table: 'users', name: 'idx_users_score', columns: ['score'], unique: false, type: 'BTREE',
              definition: 'CREATE INDEX idx_users_score ON users (score) WHERE score > 0' }
          ]
        )
      end
    end

    describe '#fetch_foreign_keys' do
      before do
        create_schema(<<~SQL)
          CREATE TABLE regions (code TEXT, country TEXT, PRIMARY KEY (code, country));
          CREATE TABLE users (id INTEGER PRIMARY KEY);
          CREATE TABLE posts (
            id INTEGER PRIMARY KEY,
            user_id INTEGER REFERENCES users (id) ON DELETE CASCADE,
            region_code TEXT,
            region_country TEXT,
            FOREIGN KEY (region_code, region_country) REFERENCES regions (code, country) ON UPDATE SET NULL
          );
        SQL
      end

      it 'returns composite keys as one entry, in declaration order' do
        expect(adapter.fetch_foreign_keys(connection)).to eq(
          [
            { table: 'posts', name: 'fk_posts_users_user_id', columns: ['user_id'], foreign_table: 'users',
              foreign_columns: ['id'], on_update: 'NO ACTION', on_delete: 'CASCADE' },
            { table: 'posts', name: 'fk_posts_regions_region_code_region_country', columns: %w[region_code region_country],
              foreign_table: 'regions', foreign_columns: %w[code country], on_update: 'SET NULL', on_delete: 'NO ACTION' }
          ]
        )
      end
    end

    describe '#fetch_views' do
      it 'extracts the query from statements with quoted view names' do
        create_schema(<<~SQL)
          CREATE TABLE users (id INTEGER PRIMARY KEY);
          CREATE VIEW IF NOT EXISTS "active users" AS SELECT id FROM users WHERE id > 0;
        SQL

        expect(adapter.fetch_views(connection)).to eq(
          [
            { schema: 'main', name: 'active users', definition: 'SELECT id FROM users WHERE id > 0',
              sql: 'CREATE VIEW "active users" AS SELECT id FROM users WHERE id > 0', updatable: false }
          ]
        )
      end
    end

    describe '#fetch_triggers' do
      it 'returns the original statement with parsed timing and event' do
        create_schema(<<~SQL)
          CREATE TABLE users (id INTEGER PRIMARY KEY);
          CREATE TRIGGER users_before_delete BEFORE DELETE ON users BEGIN SELECT 1; END;
        SQL

        expect(adapter.fetch_triggers(connection)).to eq(
          [
            { schema: 'main', name: 'users_before_delete', table_name: 'users', timing: 'BEFORE', event: 'DELETE',
              definition: 'CREATE TRIGGER users_before_delete BEFORE DELETE ON users BEGIN SELECT 1; END' }
          ]
        )
      end
    end
  end

  describe '#fetch_custom_types' do
    it 'returns empty array (SQLite does not have custom types)' do
      expect(adapter.fetch_custom_types(connection)).to eq([])
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
end
