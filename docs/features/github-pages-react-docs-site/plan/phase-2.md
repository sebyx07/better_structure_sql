# Phase 2: Content Pages and Database-Specific Guides

## Objective

Create comprehensive content pages with detailed guides for each database (PostgreSQL, MySQL, SQLite), including real-world examples and tutorials showing how to use advanced database features effectively with BetterStructureSql.

## Deliverables

### 1. Getting Started Pages

**Installation Guide** (`src/pages/GettingStarted/Installation.jsx`):

Content structure:
- Installation via Bundler (add to Gemfile)
- Database-specific adapter installation (pg, mysql2, sqlite3)
- Generator command: `rails generate better_structure_sql:install`
- Migration generation for schema_versions table
- Verify installation steps

Code examples for each database:
```ruby
# For PostgreSQL
gem 'better_structure_sql'
gem 'pg', '>= 1.0'

# For MySQL
gem 'better_structure_sql'
gem 'mysql2', '>= 0.5'

# For SQLite
gem 'better_structure_sql'
gem 'sqlite3', '>= 1.4'
```

**Quick Start Guide** (`src/pages/GettingStarted/QuickStart.jsx`):

5-minute tutorial:
1. Install gem and adapter
2. Run generator
3. Configure initializer (basic config)
4. Run `rake db:schema:dump_better`
5. View clean structure.sql output
6. Commit to git and see clean diff

**Configuration Guide** (`src/pages/GettingStarted/Configuration.jsx`):

Configuration options with examples:
- Single-file vs multi-file output
- Feature toggles (extensions, views, functions, triggers)
- Schema versioning settings
- Custom output paths
- Search path configuration
- Database-specific options

Split into sections:
- Basic configuration (most common)
- Advanced configuration (multi-file, versioning)
- Database-specific configuration

### 2. PostgreSQL Guide

**PostgreSQL Features Page** (`src/pages/Databases/PostgreSQL.jsx`):

#### Extensions Tutorial

Show how to use and maintain PostgreSQL extensions:

```sql
-- BetterStructureSql cleanly dumps this
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS uuid-ossp WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
```

Tutorial steps:
1. Enable extension in migration
2. Run dump - see extension in output
3. Use extension features in application
4. Example: UUID primary keys with uuid-ossp

#### Custom Types and Enums Tutorial

Show enum type creation and usage:

```ruby
# Migration
class AddStatusEnum < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE TYPE order_status AS ENUM ('pending', 'processing', 'shipped', 'delivered', 'cancelled');
    SQL
  end
end
```

```sql
-- BetterStructureSql output
CREATE TYPE order_status AS ENUM (
  'pending',
  'processing',
  'shipped',
  'delivered',
  'cancelled'
);

CREATE TABLE orders (
  id bigserial PRIMARY KEY,
  status order_status NOT NULL DEFAULT 'pending'
);
```

Tutorial benefits:
- Type safety at database level
- Clear enum values in schema dump
- Easy to version control enum changes

#### Functions and Triggers Tutorial

Example: Automatic timestamp update trigger

```ruby
# Migration
class AddUpdatedAtTrigger < ActiveRecord::Migration[7.0]
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
end
```

```sql
-- BetterStructureSql cleanly dumps both function and trigger
CREATE FUNCTION update_updated_at_column() RETURNS trigger
  LANGUAGE plpgsql
  AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

Tutorial benefits:
- DRY principle - trigger handles timestamps
- Database enforces logic consistently
- Clean schema dump shows function + trigger
- Version controlled alongside tables

#### Materialized Views Tutorial

Example: Analytics summary view

```ruby
# Migration
class AddUserStatsMaterializedView < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE MATERIALIZED VIEW user_stats AS
      SELECT
        u.id,
        u.email,
        COUNT(o.id) AS order_count,
        SUM(o.total) AS total_spent,
        MAX(o.created_at) AS last_order_at
      FROM users u
      LEFT JOIN orders o ON o.user_id = u.id
      GROUP BY u.id, u.email;

      CREATE UNIQUE INDEX ON user_stats (id);
    SQL
  end
end
```

```sql
-- BetterStructureSql output
CREATE MATERIALIZED VIEW user_stats AS
SELECT
  u.id,
  u.email,
  COUNT(o.id) AS order_count,
  SUM(o.total) AS total_spent,
  MAX(o.created_at) AS last_order_at
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.email;

CREATE UNIQUE INDEX index_user_stats_on_id ON user_stats (id);
```

Tutorial workflow:
1. Create materialized view in migration
2. Refresh periodically: `REFRESH MATERIALIZED VIEW user_stats`
3. Query like a table: `UserStat.find(user_id)`
4. Schema dump shows full view definition

Benefits:
- Fast complex queries (pre-computed)
- Clean schema representation
- Easy to modify and version control

#### Partitioned Tables Tutorial

Example: Time-series partitioning for logs

```ruby
# Migration
class CreatePartitionedLogs < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE TABLE logs (
        id bigserial,
        created_at timestamp NOT NULL,
        message text,
        PRIMARY KEY (id, created_at)
      ) PARTITION BY RANGE (created_at);

      CREATE TABLE logs_2024_01 PARTITION OF logs
        FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

      CREATE TABLE logs_2024_02 PARTITION OF logs
        FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
    SQL
  end
end
```

Tutorial benefits:
- Handle billions of rows efficiently
- Automatic partition routing
- Old partition archival/deletion
- BetterStructureSql dumps partition structure

### 3. MySQL Guide

**MySQL Features Page** (`src/pages/Databases/MySQL.jsx`):

#### Stored Procedures Tutorial

Example: User activation procedure

```ruby
# Migration
class AddUserActivationProcedure < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE PROCEDURE activate_user(IN user_id BIGINT)
      BEGIN
        UPDATE users
        SET status = 'active', activated_at = NOW()
        WHERE id = user_id;

        INSERT INTO audit_logs (action, user_id, created_at)
        VALUES ('user_activated', user_id, NOW());
      END
    SQL
  end
end
```

```sql
-- BetterStructureSql output
CREATE PROCEDURE activate_user(IN user_id BIGINT)
BEGIN
  UPDATE users
  SET status = 'active', activated_at = NOW()
  WHERE id = user_id;

  INSERT INTO audit_logs (action, user_id, created_at)
  VALUES ('user_activated', user_id, NOW());
END;
```

Tutorial usage:
```ruby
# Call from Rails
ActiveRecord::Base.connection.execute("CALL activate_user(#{user.id})")
```

Benefits:
- Multi-statement transactions
- Database-level business logic
- Performance optimization
- Version controlled via schema dump

#### MySQL Triggers Tutorial

Example: Order total calculation trigger

```ruby
# Migration
class AddOrderTotalTrigger < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE TRIGGER calculate_order_total
      BEFORE INSERT ON orders
      FOR EACH ROW
      BEGIN
        SET NEW.total = (
          SELECT SUM(price * quantity)
          FROM order_items
          WHERE order_id = NEW.id
        );
      END
    SQL
  end
end
```

#### ENUM and SET Types Tutorial

Example: User roles with SET type (multi-select)

```ruby
# Migration
class AddUserRoles < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      ALTER TABLE users
      ADD COLUMN roles SET('admin', 'editor', 'viewer', 'moderator')
      NOT NULL DEFAULT 'viewer';
    SQL
  end
end
```

```sql
-- BetterStructureSql output
CREATE TABLE users (
  id bigint AUTO_INCREMENT PRIMARY KEY,
  roles set('admin','editor','viewer','moderator') NOT NULL DEFAULT 'viewer'
);
```

Tutorial usage:
- Single role: `roles = 'admin'`
- Multiple roles: `roles = 'admin,editor'`
- Query: `WHERE FIND_IN_SET('admin', roles)`

#### Character Sets and Collations Tutorial

Show proper UTF-8 configuration:

```ruby
# config/database.yml
production:
  adapter: mysql2
  encoding: utf8mb4
  collation: utf8mb4_unicode_ci
```

```sql
-- BetterStructureSql includes character set info
CREATE TABLE posts (
  id bigint AUTO_INCREMENT PRIMARY KEY,
  title varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 4. SQLite Guide

**SQLite Features Page** (`src/pages/Databases/SQLite.jsx`):

#### PRAGMA Settings Tutorial

Example: Essential SQLite optimizations

```ruby
# config/database.yml (development)
development:
  adapter: sqlite3
  database: db/development.sqlite3
  # BetterStructureSql will dump these as PRAGMA statements
```

```sql
-- BetterStructureSql output header
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA busy_timeout = 5000;
```

Tutorial explanation:
- `foreign_keys = ON` - Enable FK constraints (off by default!)
- `journal_mode = WAL` - Better concurrency
- `synchronous = NORMAL` - Balance safety/performance
- `busy_timeout` - Handle lock contention

#### Inline Foreign Keys Tutorial

SQLite foreign keys defined inline with CREATE TABLE:

```ruby
# Migration
class CreateComments < ActiveRecord::Migration[7.0]
  def change
    create_table :comments do |t|
      t.references :post, foreign_key: true
      t.text :body
      t.timestamps
    end
  end
end
```

```sql
-- BetterStructureSql output
CREATE TABLE comments (
  id integer PRIMARY KEY AUTOINCREMENT,
  post_id integer NOT NULL,
  body text,
  created_at datetime(6) NOT NULL,
  updated_at datetime(6) NOT NULL,
  FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
);

CREATE INDEX index_comments_on_post_id ON comments(post_id);
```

#### Type Affinities Tutorial

Explain SQLite's flexible typing:

```sql
-- SQLite stores everything flexibly but uses type affinities
CREATE TABLE products (
  id INTEGER PRIMARY KEY,        -- Integer affinity
  name TEXT,                     -- Text affinity
  price REAL,                    -- Real affinity (float)
  quantity NUMERIC,              -- Numeric affinity (flexible)
  metadata BLOB                  -- Blob affinity (binary)
);
```

Tutorial tips:
- Use standard SQL types (Rails migrations handle this)
- SQLite converts types intelligently
- BetterStructureSql shows actual declared types

#### CHECK Constraints for Enums Tutorial

SQLite doesn't have native ENUMs - use CHECK constraints:

```ruby
# Migration
class AddStatusToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :status, :string, default: 'pending'
    add_check_constraint :orders, "status IN ('pending', 'processing', 'shipped', 'delivered')", name: 'valid_status'
  end
end
```

```sql
-- BetterStructureSql output
CREATE TABLE orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  status TEXT DEFAULT 'pending',
  CONSTRAINT valid_status CHECK (status IN ('pending', 'processing', 'shipped', 'delivered'))
);
```

### 5. Features Pages

**Schema Versioning Page** (`src/pages/Features/SchemaVersioning.jsx`):

Content sections:
- What is schema versioning?
- Why store schema versions in production?
- Configuration tutorial
- Production workflow tutorial
- Web UI access tutorial
- Comparing versions tutorial
- Retention management

**Multi-File Output Page** (`src/pages/Features/MultiFileOutput.jsx`):

Content sections:
- Why multi-file output? (AI context, massive schemas, git diffs)
- When to use it (1000+ tables, AI-assisted development, large teams)
- Configuration tutorial
- Directory structure explanation
- Git workflow benefits
- AI benefits: No more 10,000+ line files for LLMs to process
- Tutorial: Migrating from single-file to multi-file

**AI and Multi-File Schema** section:
```
Problem: LLMs struggle with 10,000+ line structure.sql files
- Context window limitations
- Slow processing
- Difficult to find specific tables
- Poor code navigation

Solution: Multi-file schema with organized directories
- Each file ~500 lines (AI-friendly chunks)
- Numbered directories show load order
- Easy to reference: "Check 4_tables/000015.sql"
- AI can navigate structure efficiently
- Find specific triggers in 9_triggers/ folder
```

**Web Engine Page** (`src/pages/Features/WebEngine.jsx`):

Content sections:
- What is the Web Engine?
- Production use case: Developer schema access
- Mounting the engine tutorial
- Authentication integration tutorial (Devise, Pundit, custom)
- Viewing schema versions tutorial
- Downloading schemas tutorial
- ZIP archive support for multi-file schemas

**Advanced Features Page** (`src/pages/Features/AdvancedFeatures.jsx`):

Content covering:
- Views tutorial (PostgreSQL, MySQL)
- Triggers tutorial (all databases)
- Functions tutorial (PostgreSQL functions, MySQL procedures)
- Partitioning tutorial (PostgreSQL)
- Extensions tutorial (PostgreSQL)
- Custom types tutorial (PostgreSQL)

### 6. Production Usage Pages

**Deployment Page** (`src/pages/Production/Deployment.jsx`):

Content:
- Production checklist
- Configuration for production
- Database setup
- Schema versioning recommendation
- Monitoring and maintenance

**After Migrate Page** (`src/pages/Production/AfterMigrate.jsx`):

Tutorial: Automatic schema storage after migrations

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  config.enable_schema_versions = true
  config.schema_versions_limit = 10
end

# Hook into after_migrate (custom initializer)
# config/initializers/schema_versioning.rb
if Rails.env.production?
  Rails.application.config.after_initialize do
    ActiveRecord::Tasks::DatabaseTasks.after_migrate do
      BetterStructureSql::Dumper.dump
      BetterStructureSql::SchemaVersions.store
      Rails.logger.info "Schema version stored after migration"
    end
  end
end
```

Workflow:
1. Deploy new code with migrations
2. Run `rake db:migrate`
3. Automatic schema dump and version storage
4. Developers can access new schema via web UI

**Engine Access Page** (`src/pages/Production/EngineAccess.jsx`):

Tutorial: Setting up developer access to production schema

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Option 1: Devise authentication
  authenticate :user, ->(user) { user.admin? || user.developer? } do
    mount BetterStructureSql::Engine => '/schema_versions'
  end

  # Option 2: Custom constraint
  class DeveloperConstraint
    def matches?(request)
      # Your auth logic (session, header, etc.)
      request.session[:user_role]&.in?(['admin', 'developer'])
    end
  end

  constraints DeveloperConstraint.new do
    mount BetterStructureSql::Engine => '/schema_versions'
  end
end
```

Tutorial workflow:
1. Developer needs production schema
2. Login to production app (read-only access)
3. Navigate to `/schema_versions`
4. View list of schema versions
5. Download latest version (single file or ZIP)
6. Load locally: `rake db:schema:load_better`
7. Now working with exact production schema

Benefits:
- No direct database access needed
- Audit trail of who accessed schemas
- Only shows schema structure (no data)
- Works with multi-file schemas (ZIP download)

### 7. Examples Page

**Examples Page** (`src/pages/Examples.jsx`):

Real-world examples showcasing:

1. **E-commerce Platform**
   - Products, orders, customers tables
   - Materialized view for sales analytics
   - Trigger for inventory management
   - Before/After pg_dump comparison

2. **Multi-Tenant SaaS**
   - 5,000+ tenant tables (via partitioning or separate tables)
   - Multi-file output demonstration
   - Directory structure visualization
   - Git diff showing only changed tables

3. **Time-Series Database**
   - Partitioned tables by month
   - Automatic partition creation function
   - Trigger for partition routing
   - 50,000+ partition tables handled cleanly

4. **Microservices Data Layer**
   - Shared views across services
   - Functions for data validation
   - Extension usage (UUID, pg_trgm)
   - Clean schema versioning

5. **Before/After Comparisons**
   - pg_dump output: 200+ lines of noise
   - BetterStructureSql: 50 lines clean SQL
   - Side-by-side comparison

### 8. Component Development

**DatabaseTabs Component** (`src/components/DatabaseTabs/DatabaseTabs.jsx`):

Tabs showing same feature across databases:
```jsx
<DatabaseTabs>
  <Tab database="postgresql" label="PostgreSQL">
    <CodeBlock language="sql">{postgresqlCode}</CodeBlock>
  </Tab>
  <Tab database="mysql" label="MySQL">
    <CodeBlock language="sql">{mysqlCode}</CodeBlock>
  </Tab>
  <Tab database="sqlite" label="SQLite">
    <CodeBlock language="sql">{sqliteCode}</CodeBlock>
  </Tab>
</DatabaseTabs>
```

**CodeBlock Component** (`src/components/CodeBlock/CodeBlock.jsx`):

Syntax-highlighted code with copy button:
- Uses react-syntax-highlighter
- Supports SQL, Ruby, YAML, Bash
- Copy to clipboard functionality
- Line numbers optional
- Highlight specific lines

## Testing Requirements

### Unit Tests
- All page components render correctly
- DatabaseTabs switches between databases
- CodeBlock displays syntax highlighting
- Copy button works in CodeBlock

### Content Tests
- All code examples are valid (syntax check)
- Tutorial steps are complete
- Links to other pages work
- Database-specific content shows correct database

### Integration Tests
- Navigation to all database guide pages
- Tab switching in DatabaseTabs
- Code copy functionality
- Responsive layout on mobile

## Success Criteria

- [x] All getting started pages complete with tutorials
- [x] PostgreSQL guide shows 5+ feature tutorials
- [x] MySQL guide shows stored procedures, triggers, SET type
- [x] SQLite guide shows PRAGMAs, CHECK constraints, inline FKs
- [x] Feature pages explain schema versioning, multi-file output, web engine
- [x] Production pages show automated workflow
- [x] Examples page has 5+ real-world scenarios
- [x] All code examples are syntax-valid and tested
- [x] DatabaseTabs component works across all guides
- [x] Tests pass with >85% coverage

## Phase Dependencies

Depends on Phase 1 (project foundation, layout components, routing).

## Estimated Effort

**Development**: 4-5 days
- Getting Started pages: 4 hours
- PostgreSQL guide: 6 hours
- MySQL guide: 5 hours
- SQLite guide: 4 hours
- Features pages: 6 hours
- Production pages: 4 hours
- Examples page: 4 hours
- Component development and testing: 5 hours

**Total**: ~38 hours
