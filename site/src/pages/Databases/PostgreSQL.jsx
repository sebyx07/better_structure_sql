import { Link } from 'react-router-dom';
import CodeBlock from '../../components/CodeBlock/CodeBlock';

function PostgreSQL() {
  return (
    <div className="container my-4">
      <div className="row">
        <div className="col-lg-10 offset-lg-1">
          <div className="postgresql-guide">
            <h1 className="mb-4">
              <i className="bi bi-database-fill-gear text-primary me-3" />
              PostgreSQL Guide
            </h1>

            <div className="alert alert-info">
              <i className="bi bi-info-circle me-2" />
              PostgreSQL has the most comprehensive feature support in BetterStructureSql with 100% coverage
              of extensions, custom types, functions, triggers, materialized views, and partitioned tables.
            </div>

            <div className="alert alert-warning">
              <i className="bi bi-download me-2" />
              <strong>Getting Started:</strong>{' '}
              <Link to="/install" className="alert-link">Install BetterStructureSql</Link>
              {' '}• PostgreSQL 12+ required •{' '}
              <a href="https://www.postgresql.org/download/" className="alert-link" target="_blank" rel="noopener noreferrer">
                Install PostgreSQL
              </a>
            </div>

      {/* UUID v8 for Better Primary Keys */}
      <section className="mb-5">
        <h2 className="border-bottom pb-2 mb-3">
          <i className="bi bi-key me-2" />
          UUID v8 for Better Primary Keys
        </h2>
        <p className="lead">
          UUID v8 provides time-ordered UUIDs that are much better for database indexes than random UUIDs.
          They maintain the benefits of UUIDs (globally unique, no sequences) while providing natural ordering.
        </p>

        <div className="alert alert-warning">
          <strong>Why UUID v8?</strong> Random UUIDs (v4) cause index fragmentation and poor B-tree performance.
          UUID v8 embeds a timestamp, so rows insert in order - dramatically faster for large tables!
        </div>

        <h4 className="mt-4">Step 1: Enable pgcrypto Extension</h4>
        <CodeBlock language="ruby" filename="db/migrate/20240101000001_enable_pgcrypto.rb">
          {`class EnablePgcrypto < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'pgcrypto'
  end
end`}
        </CodeBlock>

        <h4 className="mt-4">Step 2: Create UUID v8 Generator Function</h4>
        <CodeBlock language="ruby" filename="db/migrate/20240101000002_create_uuid_v8_function.rb">
          {`class CreateUuidV8Function < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION uuid_generate_v8()
      RETURNS uuid
      AS $$
      DECLARE
        timestamp    timestamptz;
        microseconds int;
      BEGIN
        timestamp    = clock_timestamp();
        microseconds = (CAST(EXTRACT(microseconds FROM timestamp)::int -
                            (FLOOR(EXTRACT(milliseconds FROM timestamp))::int * 1000)
                            AS double precision) * 4.096)::int;

        -- Use random v4 uuid as starting point (which has the same variant we need)
        -- then overlay timestamp
        -- then set version 8 and add microseconds
        RETURN encode(
          set_byte(
            set_byte(
              overlay(uuid_send(gen_random_uuid())
                      PLACING substring(int8send(FLOOR(EXTRACT(epoch FROM timestamp) * 1000)::bigint) FROM 3)
                      FROM 1 FOR 6
              ),
              6, (b'1000' || (microseconds >> 8)::bit(4))::bit(8)::int
            ),
            7, microseconds::bit(8)::int
          ),
          'hex')::uuid;
      END
      $$
      LANGUAGE plpgsql
      VOLATILE;
    SQL
  end

  def down
    execute 'DROP FUNCTION IF EXISTS uuid_generate_v8();'
  end
end`}
        </CodeBlock>

        <h4 className="mt-4">Step 3: Use UUID v8 in Your Tables</h4>
        <CodeBlock language="ruby" filename="db/migrate/20240101000003_create_users_with_uuid_v8.rb">
          {`class CreateUsersWithUuidV8 < ActiveRecord::Migration[7.0]
  def change
    create_table :users, id: false do |t|
      t.column :id, :uuid, null: false, default: -> { 'uuid_generate_v8()' }, primary_key: true
      t.string :email, null: false
      t.string :name
      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end`}
        </CodeBlock>

        <h5>BetterStructureSql Output</h5>
        <CodeBlock language="sql" filename="db/structure.sql">
          {`-- Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;

-- Functions
CREATE FUNCTION uuid_generate_v8() RETURNS uuid
  LANGUAGE plpgsql VOLATILE
  AS $$
DECLARE
  timestamp    timestamptz;
  microseconds int;
BEGIN
  timestamp    = clock_timestamp();
  microseconds = (CAST(EXTRACT(microseconds FROM timestamp)::int -
                      (FLOOR(EXTRACT(milliseconds FROM timestamp))::int * 1000)
                      AS double precision) * 4.096)::int;

  RETURN encode(
    set_byte(
      set_byte(
        overlay(uuid_send(gen_random_uuid())
                PLACING substring(int8send(FLOOR(EXTRACT(epoch FROM timestamp) * 1000)::bigint) FROM 3)
                FROM 1 FOR 6
        ),
        6, (b'1000' || (microseconds >> 8)::bit(4))::bit(8)::int
      ),
      7, microseconds::bit(8)::int
    ),
    'hex')::uuid;
END
$$;

-- Tables
CREATE TABLE users (
  id uuid DEFAULT uuid_generate_v8() NOT NULL PRIMARY KEY,
  email varchar NOT NULL,
  name varchar,
  created_at timestamp(6) NOT NULL,
  updated_at timestamp(6) NOT NULL
);

CREATE UNIQUE INDEX index_users_on_email ON users (email);`}
        </CodeBlock>

        <div className="alert alert-success mt-3">
          <strong>Benefits:</strong>
          <ul className="mb-0">
            <li>🚀 <strong>50-80% faster inserts</strong> than random UUIDs (v4)</li>
            <li>📊 Better index performance (time-ordered = less fragmentation)</li>
            <li>🌍 Globally unique across databases (great for distributed systems)</li>
            <li>🔍 Can sort by ID to get chronological order</li>
            <li>🔒 No sequence contention issues</li>
          </ul>
        </div>
      </section>

      {/* Audit Logging with Triggers */}
      <section className="mb-5">
        <h2 className="border-bottom pb-2 mb-3">
          <i className="bi bi-journal-text me-2" />
          Audit Logging with Triggers
        </h2>
        <p className="lead">
          Automatically track all changes to sensitive tables. Perfect for compliance,
          debugging, and understanding your data history.
        </p>

        <h4 className="mt-4">Step 1: Create Audit Log Table</h4>
        <CodeBlock language="ruby" filename="db/migrate/20240101000010_create_audit_logs.rb">
          {`class CreateAuditLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :audit_logs do |t|
      t.string :table_name, null: false
      t.string :operation, null: false  # INSERT, UPDATE, DELETE
      t.bigint :record_id
      t.jsonb :old_values
      t.jsonb :new_values
      t.jsonb :changed_fields
      t.string :user_id
      t.inet :ip_address
      t.timestamp :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :audit_logs, :table_name
    add_index :audit_logs, :record_id
    add_index :audit_logs, :operation
    add_index :audit_logs, :created_at
  end
end`}
        </CodeBlock>

        <h4 className="mt-4">Step 2: Create Generic Audit Function</h4>
        <CodeBlock language="ruby" filename="db/migrate/20240101000011_create_audit_trigger_function.rb">
          {`class CreateAuditTriggerFunction < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION audit_trigger_function()
      RETURNS TRIGGER AS $$
      DECLARE
        old_data jsonb;
        new_data jsonb;
        changed jsonb;
      BEGIN
        IF (TG_OP = 'DELETE') THEN
          old_data = to_jsonb(OLD);
          INSERT INTO audit_logs (
            table_name, operation, record_id,
            old_values, created_at
          ) VALUES (
            TG_TABLE_NAME, TG_OP, OLD.id,
            old_data, CURRENT_TIMESTAMP
          );
          RETURN OLD;
        ELSIF (TG_OP = 'UPDATE') THEN
          old_data = to_jsonb(OLD);
          new_data = to_jsonb(NEW);

          -- Calculate changed fields
          SELECT jsonb_object_agg(key, value)
          INTO changed
          FROM jsonb_each(new_data)
          WHERE value IS DISTINCT FROM old_data->key;

          INSERT INTO audit_logs (
            table_name, operation, record_id,
            old_values, new_values, changed_fields, created_at
          ) VALUES (
            TG_TABLE_NAME, TG_OP, NEW.id,
            old_data, new_data, changed, CURRENT_TIMESTAMP
          );
          RETURN NEW;
        ELSIF (TG_OP = 'INSERT') THEN
          new_data = to_jsonb(NEW);
          INSERT INTO audit_logs (
            table_name, operation, record_id,
            new_values, created_at
          ) VALUES (
            TG_TABLE_NAME, TG_OP, NEW.id,
            new_data, CURRENT_TIMESTAMP
          );
          RETURN NEW;
        END IF;
      END;
      $$ LANGUAGE plpgsql;
    SQL
  end

  def down
    execute 'DROP FUNCTION IF EXISTS audit_trigger_function() CASCADE;'
  end
end`}
        </CodeBlock>

        <h4 className="mt-4">Step 3: Apply Trigger to Tables</h4>
        <CodeBlock language="ruby" filename="db/migrate/20240101000012_add_audit_triggers.rb">
          {`class AddAuditTriggers < ActiveRecord::Migration[7.0]
  def up
    # Audit sensitive tables
    %w[users orders payments].each do |table_name|
      execute <<-SQL
        CREATE TRIGGER audit_#{table_name}
        AFTER INSERT OR UPDATE OR DELETE ON #{table_name}
        FOR EACH ROW
        EXECUTE FUNCTION audit_trigger_function();
      SQL
    end
  end

  def down
    %w[users orders payments].each do |table_name|
      execute "DROP TRIGGER IF EXISTS audit_#{table_name} ON #{table_name};"
    end
  end
end`}
        </CodeBlock>

        <h5>Query Audit History</h5>
        <CodeBlock language="ruby">
          {`# Find all changes to a user
AuditLog.where(table_name: 'users', record_id: user.id).order(created_at: :desc)

# See what changed in last update
audit = AuditLog.where(table_name: 'users', record_id: user.id, operation: 'UPDATE').last
audit.changed_fields
# => {"email"=>{"new"=>"new@example.com", "old"=>"old@example.com"}}

# Track who deleted records
AuditLog.where(operation: 'DELETE').order(created_at: :desc)`}
        </CodeBlock>

        <div className="alert alert-success mt-3">
          <strong>Benefits:</strong>
          <ul className="mb-0">
            <li>📝 Complete change history automatically</li>
            <li>🔍 Debug production issues (see exact values before/after)</li>
            <li>✅ Compliance requirements (GDPR, SOC2, HIPAA)</li>
            <li>🔙 Rollback capability (restore old values)</li>
            <li>⚡ Zero application code changes needed</li>
          </ul>
        </div>
      </section>

      {/* Full-Text Search */}
      <section className="mb-5">
        <h2 className="border-bottom pb-2 mb-3">
          <i className="bi bi-search me-2" />
          Full-Text Search with pg_trgm
        </h2>
        <p className="lead">
          Fast, fuzzy search across your text columns. Better than LIKE queries,
          with typo tolerance and ranked results.
        </p>

        <h4 className="mt-4">Step 1: Enable pg_trgm Extension</h4>
        <CodeBlock language="ruby" filename="db/migrate/20240101000020_enable_pg_trgm.rb">
          {`class EnablePgTrgm < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'pg_trgm'
  end
end`}
        </CodeBlock>

        <h4 className="mt-4">Step 2: Add GIN Index for Fast Searches</h4>
        <CodeBlock language="ruby" filename="db/migrate/20240101000021_add_search_indexes.rb">
          {`class AddSearchIndexes < ActiveRecord::Migration[7.0]
  def change
    # GIN index for trigram similarity search
    add_index :products, :name, using: :gin, opclass: :gin_trgm_ops, name: 'idx_products_name_trgm'
    add_index :products, :description, using: :gin, opclass: :gin_trgm_ops, name: 'idx_products_desc_trgm'

    # GIN index for full-text search (alternative approach)
    execute <<-SQL
      CREATE INDEX idx_products_fulltext ON products
      USING GIN (to_tsvector('english', name || ' ' || description));
    SQL
  end

  def down
    remove_index :products, name: 'idx_products_name_trgm'
    remove_index :products, name: 'idx_products_desc_trgm'
    execute 'DROP INDEX IF EXISTS idx_products_fulltext;'
  end
end`}
        </CodeBlock>

        <h4 className="mt-4">Step 3: Use in Your Rails Models</h4>
        <CodeBlock language="ruby" filename="app/models/product.rb">
          {`class Product < ApplicationRecord
  # Fuzzy search with typo tolerance
  scope :search, ->(query) {
    where("name % ?", query)
      .or(where("description % ?", query))
      .order(Arel.sql("similarity(name, #{connection.quote(query)}) DESC"))
  }

  # Full-text search (more precise)
  scope :fulltext_search, ->(query) {
    where(
      "to_tsvector('english', name || ' ' || description) @@ plainto_tsquery('english', ?)",
      query
    ).order(
      Arel.sql("ts_rank(to_tsvector('english', name || ' ' || description), plainto_tsquery('english', #{connection.quote(query)})) DESC")
    )
  }
end

# Usage:
Product.search('wireles charger')  # Finds "Wireless Charger" (typo tolerant!)
Product.fulltext_search('fast charging cable')  # Ranked by relevance`}
        </CodeBlock>

        <div className="alert alert-success mt-3">
          <strong>Benefits:</strong>
          <ul className="mb-0">
            <li>🚀 1000x faster than LIKE &apos;%query%&apos; queries</li>
            <li>✨ Typo tolerance - finds &quot;wireles&quot; when searching for &quot;wireless&quot;</li>
            <li>📊 Ranked results by relevance</li>
            <li>🌍 Multi-language support</li>
            <li>⚡ Scales to millions of records</li>
          </ul>
        </div>
      </section>

      {/* Custom Types and Enums */}
      <section className="mb-5">
        <h2 className="border-bottom pb-2 mb-3">
          <i className="bi bi-list-check me-2" />
          Custom Types and Enums Tutorial
        </h2>
        <p className="lead">
          PostgreSQL ENUM types provide type safety at the database level.
          BetterStructureSql outputs clean, readable enum definitions.
        </p>

        <h4 className="mt-4">Example: Order Status Enum</h4>

        <h5>Migration</h5>
        <CodeBlock language="ruby" filename="db/migrate/20240101000003_add_order_status_enum.rb">
          {`class AddOrderStatusEnum < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE TYPE order_status AS ENUM (
        'pending',
        'processing',
        'shipped',
        'delivered',
        'cancelled'
      );
    SQL
  end

  def down
    execute <<-SQL
      DROP TYPE order_status;
    SQL
  end
end`}
        </CodeBlock>

        <h5>BetterStructureSql Output</h5>
        <CodeBlock language="sql" filename="db/structure.sql">
          {`-- Custom Types
CREATE TYPE order_status AS ENUM (
  'pending',
  'processing',
  'shipped',
  'delivered',
  'cancelled'
);

-- Tables
CREATE TABLE orders (
  id bigserial PRIMARY KEY,
  status order_status NOT NULL DEFAULT 'pending',
  total decimal(10,2),
  created_at timestamp(6) NOT NULL,
  updated_at timestamp(6) NOT NULL
);`}
        </CodeBlock>

        <div className="alert alert-success mt-3">
          <strong>Benefits:</strong>
          <ul className="mb-0">
            <li>Database-level type safety</li>
            <li>Clear enum values in schema</li>
            <li>Easy to version control enum changes</li>
            <li>Better than CHECK constraints</li>
          </ul>
        </div>
      </section>

      {/* Functions and Triggers */}
      <section className="mb-5">
        <h2 className="border-bottom pb-2 mb-3">
          <i className="bi bi-lightning me-2" />
          Functions and Triggers Tutorial
        </h2>
        <p className="lead">
          Triggers automate database operations. BetterStructureSql cleanly dumps both the function
          and trigger definitions together.
        </p>

        <h4 className="mt-4">Example: Automatic Timestamp Update</h4>

        <h5>Migration</h5>
        <CodeBlock language="ruby" filename="db/migrate/20240101000004_add_updated_at_trigger.rb">
          {`class AddUpdatedAtTrigger < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER update_users_updated_at
        BEFORE UPDATE ON users
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    SQL
  end

  def down
    execute 'DROP TRIGGER IF EXISTS update_users_updated_at ON users;'
    execute 'DROP FUNCTION IF EXISTS update_updated_at_column();'
  end
end`}
        </CodeBlock>

        <h5>BetterStructureSql Output</h5>
        <CodeBlock language="sql" filename="db/structure.sql">
          {`-- Functions
CREATE FUNCTION update_updated_at_column() RETURNS trigger
  LANGUAGE plpgsql
  AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Triggers
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();`}
        </CodeBlock>

        <div className="alert alert-success mt-3">
          <strong>Benefits:</strong>
          <ul className="mb-0">
            <li>DRY principle - trigger handles timestamps automatically</li>
            <li>Database enforces logic consistently</li>
            <li>Clean schema dump shows function + trigger</li>
            <li>Version controlled alongside tables</li>
          </ul>
        </div>
      </section>

      {/* Materialized Views */}
      <section className="mb-5">
        <h2 className="border-bottom pb-2 mb-3">
          <i className="bi bi-eye me-2" />
          Materialized Views Tutorial
        </h2>
        <p className="lead">
          Materialized views cache complex query results for fast access.
          Perfect for analytics and reporting.
        </p>

        <h4 className="mt-4">Example: User Statistics View</h4>

        <h5>Migration</h5>
        <CodeBlock language="ruby" filename="db/migrate/20240101000005_add_user_stats_view.rb">
          {`class AddUserStatsView < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE MATERIALIZED VIEW user_stats AS
      SELECT
        u.id,
        u.email,
        COUNT(o.id) AS order_count,
        COALESCE(SUM(o.total), 0) AS total_spent,
        MAX(o.created_at) AS last_order_at
      FROM users u
      LEFT JOIN orders o ON o.user_id = u.id
      GROUP BY u.id, u.email;

      CREATE UNIQUE INDEX ON user_stats (id);
    SQL
  end

  def down
    execute 'DROP MATERIALIZED VIEW IF EXISTS user_stats;'
  end
end`}
        </CodeBlock>

        <h5>BetterStructureSql Output</h5>
        <CodeBlock language="sql" filename="db/structure.sql">
          {`-- Materialized Views
CREATE MATERIALIZED VIEW user_stats AS
SELECT
  u.id,
  u.email,
  COUNT(o.id) AS order_count,
  COALESCE(SUM(o.total), 0) AS total_spent,
  MAX(o.created_at) AS last_order_at
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.email;

CREATE UNIQUE INDEX index_user_stats_on_id ON user_stats (id);`}
        </CodeBlock>

        <h5>Refreshing the View</h5>
        <CodeBlock language="ruby">
          {`# Refresh periodically (e.g., in a cron job)
ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW user_stats')

# Or refresh concurrently (non-blocking)
ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW CONCURRENTLY user_stats')`}
        </CodeBlock>

        <div className="alert alert-success mt-3">
          <strong>Benefits:</strong>
          <ul className="mb-0">
            <li>Fast complex queries (pre-computed results)</li>
            <li>Clean schema representation</li>
            <li>Easy to modify and version control</li>
            <li>Reduces load on main tables</li>
          </ul>
        </div>
      </section>

      {/* Partitioned Tables */}
      <section className="mb-5">
        <h2 className="border-bottom pb-2 mb-3">
          <i className="bi bi-table me-2" />
          Partitioned Tables Tutorial
        </h2>
        <p className="lead">
          Table partitioning splits large tables into smaller, manageable pieces.
          Perfect for time-series data and massive datasets.
        </p>

        <h4 className="mt-4">Example: Time-Series Event Logs</h4>

        <h5>Migration</h5>
        <CodeBlock language="ruby" filename="db/migrate/20240101000006_create_partitioned_logs.rb">
          {`class CreatePartitionedLogs < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE TABLE event_logs (
        id bigserial,
        event_type varchar(50) NOT NULL,
        user_id bigint,
        created_at timestamp NOT NULL,
        data jsonb,
        PRIMARY KEY (id, created_at)
      ) PARTITION BY RANGE (created_at);

      -- Create partitions for each month
      CREATE TABLE event_logs_2024_01 PARTITION OF event_logs
        FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

      CREATE TABLE event_logs_2024_02 PARTITION OF event_logs
        FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

      CREATE TABLE event_logs_2024_03 PARTITION OF event_logs
        FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');

      -- Create index on each partition
      CREATE INDEX ON event_logs_2024_01 (user_id);
      CREATE INDEX ON event_logs_2024_02 (user_id);
      CREATE INDEX ON event_logs_2024_03 (user_id);
    SQL
  end

  def down
    execute 'DROP TABLE IF EXISTS event_logs CASCADE;'
  end
end`}
        </CodeBlock>

        <h5>BetterStructureSql Output</h5>
        <CodeBlock language="sql" filename="db/structure.sql">
          {`-- Partitioned Tables
CREATE TABLE event_logs (
  id bigserial,
  event_type varchar(50) NOT NULL,
  user_id bigint,
  created_at timestamp NOT NULL,
  data jsonb,
  PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Partitions
CREATE TABLE event_logs_2024_01 PARTITION OF event_logs
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE event_logs_2024_02 PARTITION OF event_logs
  FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

CREATE TABLE event_logs_2024_03 PARTITION OF event_logs
  FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');`}
        </CodeBlock>

        <div className="alert alert-success mt-3">
          <strong>Benefits:</strong>
          <ul className="mb-0">
            <li>Handle billions of rows efficiently</li>
            <li>Automatic partition routing</li>
            <li>Easy to archive or delete old partitions</li>
            <li>Improved query performance on time-range queries</li>
            <li>BetterStructureSql dumps complete partition structure</li>
          </ul>
        </div>
      </section>

      {/* Summary */}
      <section className="mb-5">
        <h2 className="border-bottom pb-2 mb-3">Summary</h2>
        <div className="row">
          <div className="col-md-6">
            <div className="card mb-3">
              <div className="card-body">
                <h5 className="card-title">
                  <i className="bi bi-check-circle-fill text-success me-2" />
                  Fully Supported Features
                </h5>
                <ul>
                  <li>Extensions (pgcrypto, uuid-ossp, pg_trgm, etc.)</li>
                  <li>Custom Types and ENUMs</li>
                  <li>Functions (plpgsql, sql)</li>
                  <li>Triggers (BEFORE, AFTER, INSTEAD OF)</li>
                  <li>Views and Materialized Views</li>
                  <li>Partitioned Tables (RANGE, LIST, HASH)</li>
                  <li>Indexes (btree, gin, gist, hash, brin)</li>
                  <li>Foreign Keys with all actions</li>
                </ul>
              </div>
            </div>
          </div>
          <div className="col-md-6">
            <div className="card mb-3">
              <div className="card-body">
                <h5 className="card-title">
                  <i className="bi bi-lightbulb-fill text-warning me-2" />
                  Best Practices
                </h5>
                <ul>
                  <li>Use ENUMs for type-safe status fields</li>
                  <li>Leverage triggers for automatic updates</li>
                  <li>Create materialized views for complex analytics</li>
                  <li>Partition large time-series tables</li>
                  <li>Enable extensions in dedicated migration</li>
                  <li>Version control all database objects</li>
                  <li>Use BetterStructureSql for clean diffs</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </section>
          </div>
        </div>
      </div>
    </div>
  );
}

export default PostgreSQL;
