import { Link } from 'react-router-dom';
import CodeBlock from '../../components/CodeBlock/CodeBlock';
import Seo from '../../components/Seo/Seo';

function SQLite() {
  return (
    <div className="container my-4">
      <Seo
        title="SQLite Guide"
        description="Using BetterStructureSql with SQLite: tables, indexes and views dumped verbatim, inline foreign keys, CHECK constraints, triggers and PRAGMA settings."
      />
      <div className="row">
        <div className="col-lg-10 offset-lg-1">
          <div className="sqlite-guide">
            <h1 className="mb-4">
              <i className="bi bi-database-dash text-info me-3" />
              SQLite Guide
            </h1>

            <div className="alert alert-info">
              <i className="bi bi-info-circle me-2" />
              SQLite is perfect for development, testing, and lightweight production apps.
              BetterStructureSql writes tables, indexes and views exactly as SQLite stores them
              (the original statements from <code>sqlite_master</code>), plus triggers.
            </div>

            <div className="alert alert-warning">
              <i className="bi bi-cone-striped me-2" />
              <strong>Round-trip tested in CI:</strong> a dump is loaded into an empty database and dumped
              again, and both the dumps and <code>sqlite_master</code> must match (the{' '}
              <code>integration-sqlite</code> job in{' '}
              <a href="https://github.com/sebyx07/better_structure_sql/blob/main/.github/workflows/ci.yml" className="alert-link" target="_blank" rel="noopener noreferrer">ci.yml</a>).
              PostgreSQL remains the primary target of BetterStructureSql. Add the <code>sqlite3</code> gem to your Gemfile.
            </div>

            <div className="alert alert-warning">
              <i className="bi bi-download me-2" />
              <strong>Getting Started:</strong>{' '}
              <Link to="/install" className="alert-link">Install Guide</Link>
              {' '}•{' '}
              <a href="https://rubygems.org/gems/better_structure_sql" className="alert-link" target="_blank" rel="noopener noreferrer">
                RubyGems
              </a>
              {' '}•{' '}
              <a href="https://www.sqlite.org/download.html" className="alert-link" target="_blank" rel="noopener noreferrer">
                Install SQLite
              </a>
            </div>

            <section className="mb-5">
              <h2 className="border-bottom pb-2 mb-3">SQLite Features</h2>
              <div className="row">
                <div className="col-md-6">
                  <h4>✅ Supported</h4>
                  <ul>
                    <li>Triggers (BEFORE/AFTER)</li>
                    <li>Views</li>
                    <li>Tables, verbatim: <code>AUTOINCREMENT</code>, <code>WITHOUT ROWID</code>, <code>STRICT</code>, collations, generated columns</li>
                    <li>Primary keys, composite included</li>
                    <li>Indexes, verbatim: UNIQUE, partial and expression indexes</li>
                    <li>Foreign Keys (inline), composite included</li>
                    <li>CHECK Constraints, named or not, and table-level UNIQUE</li>
                    <li>PRAGMAs stored in the database file: <code>application_id</code>, <code>auto_vacuum</code>, <code>user_version</code>, when non-zero</li>
                  </ul>
                </div>
                <div className="col-md-6">
                  <h4>❌ Not Supported</h4>
                  <ul>
                    <li>Extensions</li>
                    <li>Stored Procedures/Functions</li>
                    <li>Materialized Views</li>
                    <li>Custom Types (uses CHECK for enums)</li>
                    <li>Sequences (uses AUTOINCREMENT)</li>
                    <li>Comments</li>
                    <li>Connection PRAGMAs (<code>journal_mode</code>, <code>synchronous</code>, ...): set them in <code>database.yml</code>, they are not part of the schema</li>
                  </ul>
                </div>
              </div>
            </section>

            {/* Essential PRAGMA Settings */}
            <section className="mb-5">
              <h2 className="border-bottom pb-2 mb-3">
                <i className="bi bi-gear me-2" />
                Essential PRAGMA Settings
              </h2>
              <p className="lead">
                Configure SQLite for optimal performance and data integrity.
              </p>

              <CodeBlock language="ruby" filename="config/database.yml">
                {`development:
  adapter: sqlite3
  database: db/development.sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
  # SQLite3 pragmas
  pragmas:
    foreign_keys: true          # Enable foreign key constraints
    journal_mode: wal           # Write-Ahead Logging for better concurrency
    synchronous: normal         # Balance safety and performance
    busy_timeout: 5000          # Wait 5 seconds if database is locked
    mmap_size: 134217728        # 128MB memory-mapped I/O
    cache_size: 2000            # 2000 pages in cache`}
              </CodeBlock>

              <div className="alert alert-warning mt-3">
                <strong>⚠️ Important:</strong> <code>foreign_keys</code> is OFF by default in SQLite!
                Always enable it to enforce referential integrity.
              </div>

              <h5 className="mt-4">What Each PRAGMA Does</h5>
              <ul>
                <li><strong>foreign_keys:</strong> Enforce FK constraints (OFF by default!)</li>
                <li><strong>journal_mode = WAL:</strong> Better concurrency (readers don&apos;t block writers)</li>
                <li><strong>synchronous = NORMAL:</strong> Fast writes, still safe for most apps</li>
                <li><strong>busy_timeout:</strong> Wait for locks instead of failing immediately</li>
                <li><strong>mmap_size:</strong> Memory-mapped I/O for faster reads</li>
                <li><strong>cache_size:</strong> More cache = fewer disk reads</li>
              </ul>
            </section>

            {/* CHECK Constraints for Enums */}
            <section className="mb-5">
              <h2 className="border-bottom pb-2 mb-3">
                <i className="bi bi-list-check me-2" />
                CHECK Constraints for Enum Simulation
              </h2>
              <p className="lead">
                SQLite doesn&apos;t have ENUMs, but CHECK constraints work great!
              </p>

              <h4 className="mt-4">Example: Order Status</h4>
              <CodeBlock language="ruby" filename="db/migrate/20240101000001_create_orders.rb">
                {`class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.integer :user_id, null: false
      t.decimal :total, precision: 10, scale: 2
      t.string :status, null: false, default: 'pending'
      t.timestamps
    end

    # Add CHECK constraint for valid statuses
    add_check_constraint :orders,
      "status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')",
      name: 'valid_order_status'

    add_index :orders, :user_id
    add_index :orders, :status
  end
end`}
              </CodeBlock>

              <h4 className="mt-4">Example: Multiple Constraints</h4>
              <CodeBlock language="ruby" filename="db/migrate/20240101000002_create_products.rb">
                {`class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :stock_quantity, null: false, default: 0
      t.string :category, null: false
      t.timestamps
    end

    # Price must be positive
    add_check_constraint :products,
      'price > 0',
      name: 'positive_price'

    # Stock can't be negative
    add_check_constraint :products,
      'stock_quantity >= 0',
      name: 'non_negative_stock'

    # Valid categories
    add_check_constraint :products,
      "category IN ('electronics', 'clothing', 'books', 'food', 'other')",
      name: 'valid_category'
  end
end`}
              </CodeBlock>

              <div className="alert alert-success mt-3">
                <strong>Benefits:</strong>
                <ul className="mb-0">
                  <li>✅ Database-level validation (can&apos;t insert invalid data)</li>
                  <li>🚀 Faster than application-level validation</li>
                  <li>📊 Query planner can use constraints for optimization</li>
                  <li>🔒 Works even if you bypass Rails (SQL console, other apps)</li>
                </ul>
              </div>
            </section>

            {/* Triggers */}
            <section className="mb-5">
              <h2 className="border-bottom pb-2 mb-3">
                <i className="bi bi-lightning me-2" />
                Triggers for Automatic Updates
              </h2>
              <p className="lead">
                Maintain data integrity automatically with triggers.
              </p>

              <h4 className="mt-4">Example: Auto-Update Timestamps</h4>
              <CodeBlock language="ruby" filename="db/migrate/20240101000003_add_updated_at_trigger.rb">
                {`class AddUpdatedAtTrigger < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE TRIGGER update_users_updated_at
      AFTER UPDATE ON users
      FOR EACH ROW
      BEGIN
        UPDATE users
        SET updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.id;
      END;
    SQL
  end

  def down
    execute 'DROP TRIGGER IF EXISTS update_users_updated_at;'
  end
end`}
              </CodeBlock>

              <h4 className="mt-4">Example: Audit Log Trigger</h4>
              <CodeBlock language="ruby" filename="db/migrate/20240101000004_add_audit_trigger.rb">
                {`class AddAuditTrigger < ActiveRecord::Migration[7.0]
  def up
    # Create audit log table
    create_table :audit_logs do |t|
      t.string :table_name, null: false
      t.string :operation, null: false  # INSERT, UPDATE, DELETE
      t.integer :record_id
      t.text :old_values
      t.text :new_values
      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end

    # Trigger for user changes
    execute <<-SQL
      CREATE TRIGGER audit_users_insert
      AFTER INSERT ON users
      FOR EACH ROW
      BEGIN
        INSERT INTO audit_logs (table_name, operation, record_id, new_values, created_at)
        VALUES ('users', 'INSERT', NEW.id,
                'email: ' || NEW.email || ', status: ' || NEW.status,
                CURRENT_TIMESTAMP);
      END;

      CREATE TRIGGER audit_users_update
      AFTER UPDATE ON users
      FOR EACH ROW
      BEGIN
        INSERT INTO audit_logs (table_name, operation, record_id, old_values, new_values, created_at)
        VALUES ('users', 'UPDATE', NEW.id,
                'email: ' || OLD.email || ', status: ' || OLD.status,
                'email: ' || NEW.email || ', status: ' || NEW.status,
                CURRENT_TIMESTAMP);
      END;

      CREATE TRIGGER audit_users_delete
      AFTER DELETE ON users
      FOR EACH ROW
      BEGIN
        INSERT INTO audit_logs (table_name, operation, record_id, old_values, created_at)
        VALUES ('users', 'DELETE', OLD.id,
                'email: ' || OLD.email || ', status: ' || OLD.status,
                CURRENT_TIMESTAMP);
      END;
    SQL
  end

  def down
    execute 'DROP TRIGGER IF EXISTS audit_users_insert;'
    execute 'DROP TRIGGER IF EXISTS audit_users_update;'
    execute 'DROP TRIGGER IF EXISTS audit_users_delete;'
    drop_table :audit_logs
  end
end`}
              </CodeBlock>

              <div className="alert alert-success mt-3">
                <strong>Benefits:</strong>
                <ul className="mb-0">
                  <li>📝 Complete change history automatically tracked</li>
                  <li>⚡ Zero application code changes needed</li>
                  <li>🔍 Debug and audit production changes easily</li>
                  <li>✅ Works even from SQL console or migrations</li>
                </ul>
              </div>
            </section>

            {/* Inline Foreign Keys */}
            <section className="mb-5">
              <h2 className="border-bottom pb-2 mb-3">
                <i className="bi bi-link-45deg me-2" />
                Inline Foreign Keys Best Practices
              </h2>
              <p className="lead">
                SQLite handles foreign keys inline with CREATE TABLE.
              </p>

              <CodeBlock language="ruby" filename="db/migrate/20240101000005_create_comments.rb">
                {`class CreateComments < ActiveRecord::Migration[7.0]
  def change
    create_table :comments do |t|
      t.integer :post_id, null: false
      t.integer :user_id, null: false
      t.text :body, null: false
      t.timestamps
    end

    # SQLite foreign keys with cascade
    add_foreign_key :comments, :posts, on_delete: :cascade
    add_foreign_key :comments, :users, on_delete: :cascade

    add_index :comments, :post_id
    add_index :comments, :user_id
  end
end`}
              </CodeBlock>

              <h5 className="mt-4">BetterStructureSql Output</h5>
              <p>
                Tables, indexes and views are written as the statements SQLite stores in{' '}
                <code>sqlite_master</code>, unchanged. A table created by a Rails migration keeps Rails&apos;
                quoting and layout; a table created with hand-written SQL keeps its own, like this one from the{' '}
                <code>integration_sqlite</code> app:
              </p>
              <CodeBlock language="sql" filename="db/structure.sql">
                {`CREATE TABLE ledger_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  region_code TEXT NOT NULL,
  region_country TEXT NOT NULL,
  amount INTEGER NOT NULL DEFAULT 0 CHECK (amount > -1000000),
  quantity INTEGER NOT NULL DEFAULT 1,
  total INTEGER GENERATED ALWAYS AS (amount * quantity) STORED,
  label TEXT AS (upper(region_code) || '-' || region_country) VIRTUAL,
  note TEXT DEFAULT 'it''s (here)',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_ledger_quantity CHECK (quantity BETWEEN 1 AND (10 * 100)),
  CONSTRAINT fk_ledger_region FOREIGN KEY (region_code, region_country)
    REFERENCES regions (code, country) ON DELETE CASCADE
);

CREATE INDEX "index_comments_on_post_id" ON "comments" ("post_id");`}
              </CodeBlock>

              <div className="alert alert-info mt-3">
                <strong>Cascade Options:</strong>
                <ul className="mb-0">
                  <li><code>ON DELETE CASCADE</code> - Delete child records when parent is deleted</li>
                  <li><code>ON DELETE SET NULL</code> - Set FK to NULL when parent deleted</li>
                  <li><code>ON DELETE RESTRICT</code> - Prevent deletion if children exist</li>
                  <li><code>ON UPDATE CASCADE</code> - Update FK when parent ID changes</li>
                </ul>
              </div>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
}

export default SQLite;
