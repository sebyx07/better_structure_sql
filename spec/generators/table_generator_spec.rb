# frozen_string_literal: true

require 'spec_helper'
require 'better_structure_sql/adapters/postgresql_adapter'
require 'better_structure_sql/adapters/mysql_adapter'
require 'better_structure_sql/adapters/sqlite_adapter'

RSpec.describe BetterStructureSql::Generators::TableGenerator do
  subject(:generator) { described_class.new(config) }

  let(:config) { BetterStructureSql::Configuration.new }

  describe '#generate' do
    context 'with simple table' do
      it 'generates CREATE TABLE statement' do
        table = {
          name: 'users',
          schema: 'public',
          columns: [
            { name: 'id', type: 'bigint', nullable: false, default: "nextval('users_id_seq'::regclass)" },
            { name: 'email', type: 'varchar', nullable: false, default: nil }
          ],
          primary_key: ['id'],
          constraints: []
        }

        result = generator.generate(table)

        expect(result).to include('CREATE TABLE IF NOT EXISTS "users" (')
        expect(result).to include('"id" bigint NOT NULL DEFAULT nextval(\'users_id_seq\'::regclass)')
        expect(result).to include('"email" varchar NOT NULL')
        expect(result).to include('PRIMARY KEY ("id")')
      end
    end

    context 'with nullable columns' do
      it 'omits NOT NULL constraint' do
        table = {
          name: 'posts',
          schema: 'public',
          columns: [
            { name: 'id', type: 'bigint', nullable: false, default: nil },
            { name: 'title', type: 'varchar', nullable: true, default: nil }
          ],
          primary_key: ['id'],
          constraints: []
        }

        result = generator.generate(table)

        expect(result).to include('"id" bigint NOT NULL')
        expect(result).to include('"title" varchar')
        expect(result).not_to include('"title" varchar NOT NULL')
      end
    end

    context 'with composite primary key' do
      it 'includes all columns in PRIMARY KEY' do
        table = {
          name: 'user_roles',
          schema: 'public',
          columns: [
            { name: 'user_id', type: 'bigint', nullable: false, default: nil },
            { name: 'role_id', type: 'bigint', nullable: false, default: nil }
          ],
          primary_key: %w[user_id role_id],
          constraints: []
        }

        result = generator.generate(table)

        expect(result).to include('PRIMARY KEY ("user_id", "role_id")')
      end
    end

    context 'with check constraint' do
      it 'includes constraint definition' do
        table = {
          name: 'products',
          schema: 'public',
          columns: [
            { name: 'id', type: 'bigint', nullable: false, default: nil },
            { name: 'price', type: 'numeric', nullable: false, default: nil }
          ],
          primary_key: ['id'],
          constraints: [
            { name: 'positive_price', type: :check, definition: 'CHECK ((price > 0))' }
          ]
        }

        result = generator.generate(table)

        expect(result).to include('CONSTRAINT "positive_price" CHECK ((price > 0))')
      end
    end

    context 'with unique constraint' do
      it 'includes constraint definition' do
        table = {
          name: 'users',
          schema: 'public',
          columns: [
            { name: 'id', type: 'bigint', nullable: false, default: nil },
            { name: 'email', type: 'varchar', nullable: false, default: nil }
          ],
          primary_key: ['id'],
          constraints: [
            { name: 'unique_email', type: :unique, definition: 'UNIQUE (email)' }
          ]
        }

        result = generator.generate(table)

        expect(result).to include('CONSTRAINT "unique_email" UNIQUE (email)')
      end
    end

    context 'with various default values' do
      it 'formats defaults correctly' do
        table = {
          name: 'test_table',
          schema: 'public',
          columns: [
            { name: 'id', type: 'bigint', nullable: false, default: nil },
            { name: 'created_at', type: 'timestamp', nullable: false, default: 'CURRENT_TIMESTAMP' },
            { name: 'is_active', type: 'boolean', nullable: false, default: 'true' },
            { name: 'count', type: 'integer', nullable: false, default: '0' },
            { name: 'status', type: 'varchar', nullable: true, default: "'pending'" }
          ],
          primary_key: ['id'],
          constraints: []
        }

        result = generator.generate(table)

        expect(result).to include('"created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP')
        expect(result).to include('"is_active" boolean NOT NULL DEFAULT true')
        expect(result).to include('"count" integer NOT NULL DEFAULT 0')
        expect(result).to include('"status" varchar DEFAULT \'pending\'')
      end
    end
  end

  describe '#generate for PostgreSQL' do
    subject(:generator) { described_class.new(config, BetterStructureSql::Adapters::PostgresqlAdapter.new(nil)) }

    let(:base_table) do
      { name: 'users', schema: 'public', columns: [], primary_key: [], constraints: [] }
    end

    it 'renders identity columns with their sequence options' do
      identity = { generation: 'ALWAYS', start_value: 100, increment: 10, min_value: 1, max_value: 9_223_372_036_854_775_807, cache_size: 1, cycle: false }
      table = base_table.merge(columns: [{ name: 'id', type: 'bigint', nullable: false, identity: }])

      expect(generator.generate(table)).to include(
        '"id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 100 INCREMENT BY 10 MINVALUE 1 MAXVALUE 9223372036854775807)'
      )
    end

    it 'renders generated columns without a DEFAULT' do
      generated = { expression: "first_name || ' ' || last_name", kind: 'STORED' }
      table = base_table.merge(columns: [{ name: 'full_name', type: 'text', nullable: true, generated: }])

      expect(generator.generate(table)).to include(%("full_name" text GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED\n))
    end

    it 'renders column collations' do
      table = base_table.merge(columns: [{ name: 'nickname', type: 'text', nullable: true, collation: '"C"' }])

      expect(generator.generate(table)).to include('"nickname" text COLLATE "C"')
    end

    it 'keeps PostgreSQL default expressions verbatim' do
      table = base_table.merge(columns: [
        { name: 'at', type: 'timestamp', nullable: true, default: 'LOCALTIMESTAMP' },
        { name: 'note', type: 'text', nullable: true, default: 'NULL::text' }
      ])
      result = generator.generate(table)

      expect(result).to include('"at" timestamp DEFAULT LOCALTIMESTAMP')
      expect(result).to include('"note" text DEFAULT NULL::text')
    end

    it 'names the primary key only when it is not the default name' do
      table = base_table.merge(columns: [{ name: 'id', type: 'bigint', nullable: false }], primary_key: ['id'])

      expect(generator.generate(table.merge(primary_key_name: 'users_pkey'))).to include("  PRIMARY KEY (\"id\")\n")
      expect(generator.generate(table.merge(primary_key_name: 'users_primary'))).to include('CONSTRAINT "users_primary" PRIMARY KEY ("id")')
    end

    it 'adds NOT VALID constraints after the table, since CREATE TABLE would validate them' do
      constraint = { name: 'positive', type: :check, definition: 'CHECK ((n > 0)) NOT VALID', validated: false }
      table = base_table.merge(columns: [{ name: 'n', type: 'integer', nullable: true }], constraints: [constraint])
      result = generator.generate(table)

      expect(result).to end_with(%(\n\nALTER TABLE "users" ADD CONSTRAINT "positive" CHECK ((n > 0)) NOT VALID;))
      expect(result).not_to include('  CONSTRAINT "positive"')
    end

    it 'restores serial sequence ownership' do
      table = base_table.merge(columns: [{ name: 'id', type: 'integer', nullable: false }],
                               owned_sequences: [{ sequence: 'users_id_seq', column: 'id' }])

      expect(generator.generate(table)).to end_with('ALTER SEQUENCE "users_id_seq" OWNED BY "users"."id";')
    end

    it 'renders partitioned tables followed by their partitions' do
      partition = { name: 'events_2024', columns: [], constraints: [], partition_of: 'events',
                    partition_bound: "FOR VALUES FROM ('2024-01-01') TO ('2025-01-01')", partitions: [] }
      default_partition = { name: 'events_default', columns: [], constraints: [], partition_of: 'events',
                            partition_bound: 'DEFAULT', partitions: [] }
      table = base_table.merge(name: 'events', columns: [{ name: 'occurred_at', type: 'date', nullable: false }],
                               partition_key: 'RANGE (occurred_at)', partitions: [partition, default_partition])

      expect(generator.generate(table)).to eq(<<~SQL.strip)
        CREATE TABLE IF NOT EXISTS "events" (
          "occurred_at" date NOT NULL
        ) PARTITION BY RANGE (occurred_at);

        CREATE TABLE IF NOT EXISTS "events_2024" PARTITION OF "events" FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

        CREATE TABLE IF NOT EXISTS "events_default" PARTITION OF "events" DEFAULT;
      SQL
    end

    it 'renders sub-partitioned partitions with their own constraints' do
      constraint = { name: 'positive_id', type: :check, definition: 'CHECK ((id > 0))', validated: true }
      table = { name: 'events_2024', columns: [], constraints: [constraint], partition_of: 'events',
                partition_bound: "FOR VALUES IN ('a')", partition_key: 'HASH (id)', partitions: [] }

      expect(generator.generate(table)).to eq(
        "CREATE TABLE IF NOT EXISTS \"events_2024\" PARTITION OF \"events\" (\n  CONSTRAINT \"positive_id\" CHECK ((id > 0))\n) " \
        "FOR VALUES IN ('a') PARTITION BY HASH (id);"
      )
    end

    it 'renders UNLOGGED, INHERITS and storage parameters' do
      table = base_table.merge(name: 'sports_cars', columns: [{ name: 'top_speed', type: 'integer', nullable: true }],
                               unlogged: true, inherits: %w[cars Vehicles], storage_parameters: 'fillfactor=70')

      expect(generator.generate(table)).to eq(<<~SQL.strip)
        CREATE UNLOGGED TABLE IF NOT EXISTS "sports_cars" (
          "top_speed" integer
        ) INHERITS ("cars", "Vehicles") WITH (fillfactor=70);
      SQL
    end

    it 'renders storage parameters and persistence of partitions' do
      table = { name: 'events_2024', columns: [], constraints: [], partition_of: 'events', partition_bound: 'DEFAULT',
                partitions: [], unlogged: true, storage_parameters: 'fillfactor=50' }

      expect(generator.generate(table))
        .to eq('CREATE UNLOGGED TABLE IF NOT EXISTS "events_2024" PARTITION OF "events" DEFAULT WITH (fillfactor=50);')
    end

    it 'quotes mixed-case and quote-containing identifiers' do
      table = base_table.merge(name: 'Odd"Name', columns: [{ name: 'Col', type: 'text', nullable: true }])

      expect(generator.generate(table)).to start_with(%{CREATE TABLE IF NOT EXISTS "Odd""Name" (\n  "Col" text})
    end
  end

  describe '#generate for MySQL' do
    subject(:generator) { described_class.new(config, BetterStructureSql::Adapters::MysqlAdapter.new(nil)) }

    before { allow(generator).to receive(:detect_adapter_name).and_return('mysql2') }

    let(:table) do
      {
        name: 'accounts', engine: 'InnoDB', collation: 'utf8mb4_unicode_ci', primary_key: ['id'], constraints: [],
        columns: [
          { name: 'id', type: 'int unsigned', nullable: false, auto_increment: true },
          { name: 'code', type: 'varchar(20)', nullable: false, collation: 'latin1_bin' },
          { name: 'name', type: 'varchar(50)', nullable: true, collation: 'utf8mb4_unicode_ci', default: "'it''s (x)'" },
          { name: 'bits', type: 'bit(3)', nullable: true, default: "b'101'" },
          { name: 'updated_at', type: 'timestamp', nullable: false, default: 'CURRENT_TIMESTAMP',
            on_update: 'CURRENT_TIMESTAMP' }
        ]
      }
    end

    it 'renders AUTO_INCREMENT, ON UPDATE, SQL defaults, non-default collations and table options' do
      expect(generator.generate(table)).to eq(<<~SQL.chomp)
        CREATE TABLE IF NOT EXISTS `accounts` (
          `id` int unsigned NOT NULL AUTO_INCREMENT,
          `code` varchar(20) COLLATE latin1_bin NOT NULL,
          `name` varchar(50) DEFAULT 'it''s (x)',
          `bits` bit(3) DEFAULT b'101',
          `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT COLLATE=utf8mb4_unicode_ci;
      SQL
    end
  end

  describe '#generate for SQLite' do
    subject(:generator) { described_class.new(config, BetterStructureSql::Adapters::SqliteAdapter.new(nil)) }

    it 'replays the original CREATE TABLE statement from sqlite_master' do
      sql = 'CREATE TABLE "k v" (k TEXT PRIMARY KEY, n INTEGER CHECK (n > 0)) WITHOUT ROWID, STRICT'
      table = { name: 'k v', sql:, columns: [{ name: 'k', type: 'TEXT', nullable: true }], primary_key: ['k'] }

      expect(generator.generate(table)).to eq("#{sql};")
    end
  end
end
