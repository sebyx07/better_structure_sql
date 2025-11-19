# Phase 2: MySQL Adapter Implementation

## Objective

Implement full MySQL adapter with information_schema introspection and MySQL SQL dialect generation. Create MySQL integration app for testing and validation.

## Deliverables

### 1. MySQL Adapter Core Implementation
**Files**:
- `lib/better_structure_sql/adapters/mysql_adapter.rb`
- `lib/better_structure_sql/adapters/mysql_config.rb`

**Tasks**:
- Implement MysqlAdapter inheriting from BaseAdapter
- Implement fetch_tables using information_schema.TABLES
- Implement fetch_indexes using information_schema.STATISTICS
- Implement fetch_foreign_keys using information_schema.TABLE_CONSTRAINTS + REFERENTIAL_CONSTRAINTS
- Implement fetch_views using information_schema.VIEWS
- Implement fetch_triggers using information_schema.TRIGGERS
- Implement fetch_types (partial: ENUM/SET support)
- Implement fetch_functions using information_schema.ROUTINES (stored procedures)
- Implement generate_table for MySQL CREATE TABLE syntax
- Implement generate_index for MySQL CREATE INDEX syntax
- Implement generate_foreign_key for MySQL ALTER TABLE ... ADD CONSTRAINT
- Implement generate_view for MySQL CREATE VIEW syntax
- Implement generate_trigger for MySQL CREATE TRIGGER syntax
- Implement generate_type for MySQL ENUM/SET (partial support)
- Implement generate_function for MySQL stored procedures
- Implement capability methods (supports_extensions? = false, etc.)
- Implement database_version detection (parse MySQL version)
- Handle MySQL version differences (5.7 vs 8.0+)

### 2. MySQL Information Schema Queries
**Query Implementations**:

**Tables and Columns**:
```sql
SELECT
  t.TABLE_NAME,
  t.TABLE_SCHEMA,
  c.COLUMN_NAME,
  c.DATA_TYPE,
  c.IS_NULLABLE,
  c.COLUMN_DEFAULT,
  c.CHARACTER_MAXIMUM_LENGTH,
  c.NUMERIC_PRECISION,
  c.NUMERIC_SCALE,
  c.EXTRA -- AUTO_INCREMENT detection
FROM information_schema.TABLES t
JOIN information_schema.COLUMNS c
  ON t.TABLE_NAME = c.TABLE_NAME
  AND t.TABLE_SCHEMA = c.TABLE_SCHEMA
WHERE t.TABLE_SCHEMA = DATABASE()
  AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY t.TABLE_NAME, c.ORDINAL_POSITION;
```

**Indexes**:
```sql
SELECT
  TABLE_NAME,
  INDEX_NAME,
  COLUMN_NAME,
  SEQ_IN_INDEX,
  NON_UNIQUE,
  INDEX_TYPE
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = DATABASE()
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;
```

**Foreign Keys**:
```sql
SELECT
  kcu.TABLE_NAME,
  kcu.CONSTRAINT_NAME,
  kcu.COLUMN_NAME,
  kcu.REFERENCED_TABLE_NAME,
  kcu.REFERENCED_COLUMN_NAME,
  rc.UPDATE_RULE,
  rc.DELETE_RULE
FROM information_schema.KEY_COLUMN_USAGE kcu
JOIN information_schema.REFERENTIAL_CONSTRAINTS rc
  ON kcu.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
  AND kcu.TABLE_SCHEMA = rc.CONSTRAINT_SCHEMA
WHERE kcu.TABLE_SCHEMA = DATABASE()
  AND kcu.REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY kcu.TABLE_NAME, kcu.CONSTRAINT_NAME;
```

**Views**:
```sql
SELECT
  TABLE_NAME,
  VIEW_DEFINITION,
  CHECK_OPTION,
  IS_UPDATABLE
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = DATABASE()
ORDER BY TABLE_NAME;
```

**Triggers**:
```sql
SELECT
  TRIGGER_NAME,
  EVENT_MANIPULATION, -- INSERT, UPDATE, DELETE
  EVENT_OBJECT_TABLE,
  ACTION_TIMING, -- BEFORE, AFTER
  ACTION_STATEMENT
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
ORDER BY EVENT_OBJECT_TABLE, TRIGGER_NAME;
```

**Stored Procedures**:
```sql
SELECT
  ROUTINE_NAME,
  ROUTINE_TYPE, -- PROCEDURE, FUNCTION
  DTD_IDENTIFIER, -- Return type for functions
  ROUTINE_DEFINITION
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = DATABASE()
  AND ROUTINE_TYPE IN ('PROCEDURE', 'FUNCTION')
ORDER BY ROUTINE_NAME;
```

### 3. MySQL Type Mapping
**Files**:
- `lib/better_structure_sql/adapters/mysql_adapter.rb` (type_mapper method)

**Mappings**:
- PostgreSQL ENUM → MySQL ENUM or SET
- PostgreSQL ARRAY → MySQL JSON
- PostgreSQL composite type → MySQL JSON object
- PostgreSQL domain → Inline CHECK constraint (MySQL 8.0.16+)
- PostgreSQL SERIAL → MySQL INT AUTO_INCREMENT
- PostgreSQL BIGSERIAL → MySQL BIGINT AUTO_INCREMENT
- PostgreSQL UUID → MySQL CHAR(36) or BINARY(16)
- PostgreSQL JSONB → MySQL JSON
- PostgreSQL BYTEA → MySQL BLOB
- PostgreSQL TEXT → MySQL TEXT
- PostgreSQL VARCHAR → MySQL VARCHAR
- PostgreSQL TIMESTAMP → MySQL DATETIME
- PostgreSQL TIMESTAMPTZ → MySQL TIMESTAMP (UTC conversion)
- PostgreSQL BOOLEAN → MySQL TINYINT(1)

### 4. MySQL SQL Generation
**Tasks**:
- Generate CREATE TABLE with MySQL syntax
- Handle AUTO_INCREMENT columns
- Generate PRIMARY KEY inline or as constraint
- Generate UNIQUE constraints inline
- Generate CHECK constraints (MySQL 8.0.16+)
- Generate DEFAULT values with MySQL syntax
- Generate CREATE INDEX with MySQL options (BTREE, HASH, FULLTEXT)
- Generate ALTER TABLE for foreign keys
- Handle ON DELETE/ON UPDATE actions
- Generate CREATE VIEW with ALGORITHM and SECURITY options
- Generate CREATE TRIGGER with timing and event
- Generate CREATE PROCEDURE for stored procedures
- Handle delimiter changes for procedure definitions
- Generate ENUM types inline with column definition
- Generate character set and collation (utf8mb4)

### 5. MySQL Integration App
**Location**: `integration_mysql/`

**Structure** (mirror integration/):
- `app/` - Rails app structure
- `config/database.yml` - MySQL configuration
- `config/initializers/better_structure_sql.rb` - MySQL-specific settings
- `db/migrate/` - MySQL-compatible migrations
- `db/seeds.rb` - Sample data
- `Gemfile` - Rails + mysql2 gem
- `Dockerfile.mysql` - MySQL-specific dependencies
- `docker-compose.mysql.yml` - MySQL service

**Database Configuration**:
```yaml
default: &default
  adapter: mysql2
  encoding: utf8mb4
  collation: utf8mb4_unicode_ci
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: <%= ENV.fetch("DB_HOST", "localhost") %>
  port: <%= ENV.fetch("DB_PORT", 3306) %>
  username: <%= ENV.fetch("DB_USERNAME", "root") %>
  password: <%= ENV.fetch("DB_PASSWORD", "") %>

development:
  <<: *default
  database: better_structure_sql_mysql_development
```

**Docker Service**:
```yaml
services:
  mysql:
    image: mysql:8.0-alpine
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: better_structure_sql_mysql_development
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-ppassword"]
      interval: 5s
      timeout: 5s
      retries: 10

  web:
    build:
      context: ../
      dockerfile: integration_mysql/Dockerfile.mysql
    depends_on:
      mysql:
        condition: service_healthy
    environment:
      DB_ADAPTER: mysql2
      DB_HOST: mysql
      DB_PORT: 3306
```

### 6. MySQL-Compatible Migrations
**Files**:
- `integration_mysql/db/migrate/` - 11+ migration files

**Adaptations**:
- Remove `enable_extension` calls (not supported)
- Replace PostgreSQL ENUMs with MySQL ENUMs (inline)
- Replace composite types with JSON columns
- Replace domains with CHECK constraints (MySQL 8.0.16+)
- Replace PostgreSQL functions with MySQL stored procedures
- Replace plpgsql with MySQL procedure language
- Replace array columns with JSON arrays
- Replace SERIAL with AUTO_INCREMENT
- Replace BYTEA with BLOB
- Keep schema versions table compatible

**Example Migration Adaptation**:
```ruby
# PostgreSQL version
create_table :users do |t|
  t.uuid :id, default: "gen_random_uuid()", null: false
  t.column :role, :user_role # ENUM type
end

# MySQL version
create_table :users, id: false do |t|
  t.string :id, limit: 36, null: false, default: -> { "(UUID())" }
  t.column :role, "ENUM('admin', 'user', 'guest')", null: false
end
add_index :users, :id, unique: true # PRIMARY KEY
```

### 7. MySQL Configuration Class
**Files**:
- `lib/better_structure_sql/adapters/mysql_config.rb`

**Settings**:
```ruby
class MysqlConfig
  attr_accessor :include_stored_procedures # default: true
  attr_accessor :include_triggers # default: true
  attr_accessor :include_views # default: true
  attr_accessor :use_show_create # default: false (use information_schema)
  attr_accessor :charset # default: utf8mb4
  attr_accessor :collation # default: utf8mb4_unicode_ci
  attr_accessor :min_version # default: 8.0
end
```

### 8. Registry Update
**Files**:
- `lib/better_structure_sql/adapters/registry.rb`

**Tasks**:
- Register MysqlAdapter for "Mysql2" adapter name
- Add adapter detection for mysql2 ActiveRecord adapter
- Validate mysql2 gem availability when MySQL detected
- Provide helpful error if mysql2 gem missing

### 9. Testing Suite for MySQL
**Files**:
- `spec/adapters/mysql_adapter_spec.rb`
- `spec/integration/mysql_dump_spec.rb`

**Tests**:
- Unit tests for MySQL introspection queries
- Unit tests for MySQL SQL generation
- Unit tests for MySQL type mapping
- Integration tests with real MySQL database
- Schema dump and load cycle
- Version storage and retrieval
- Multi-file output with MySQL
- Feature capability detection
- Version-specific feature tests (8.0 vs 5.7)

## Testing Requirements

### Unit Tests
- MysqlAdapter implements all BaseAdapter methods
- fetch_tables returns normalized table structures
- fetch_indexes handles multi-column indexes
- fetch_foreign_keys handles CASCADE/RESTRICT/SET NULL
- generate_table produces valid MySQL CREATE TABLE
- generate_index produces valid MySQL CREATE INDEX
- Type mapping converts PostgreSQL types correctly
- Capability methods return correct values (supports_extensions? = false)
- Version detection parses MySQL version strings
- MySQL 8.0+ enables check constraints
- MySQL 5.7 disables check constraints

### Integration Tests
- Full schema dump with MySQL database
- Schema load restores database correctly
- Foreign keys created in correct order
- Indexes created with correct types
- Views created successfully
- Stored procedures created successfully
- Triggers created successfully
- Schema versioning works with MySQL
- Multi-file output works with MySQL
- ZipGenerator works with MySQL schemas

### Comparison Tests
- Dump MySQL database with BetterStructureSql
- Dump same database with mysqldump
- Compare object lists (tables, indexes, foreign keys)
- Verify completeness of BetterStructureSql output
- Verify deterministic ordering

### Edge Cases
- Empty MySQL database
- MySQL database with reserved keywords
- Tables with AUTO_INCREMENT gaps
- Foreign keys with circular dependencies
- Views depending on other views
- Stored procedures with delimiter changes
- Triggers with BEFORE/AFTER timing
- Large TEXT/BLOB columns
- JSON columns with complex data

## Success Criteria

- MysqlAdapter passes all unit tests
- Integration app runs successfully with MySQL
- Full dump/load cycle works correctly
- Schema output is deterministic (identical on repeated dumps)
- Schema versioning stores and retrieves MySQL schemas
- Multi-file output works with MySQL
- 80%+ feature parity with PostgreSQL adapter
- Performance within 20% of mysqldump
- Documentation complete for MySQL usage
- CI testing includes MySQL matrix

## Dependencies

### External Dependencies
- mysql2 gem (>= 0.5)
- MySQL 8.0+ (recommended, 5.7 partial support)
- Docker mysql:8.0-alpine image
- Rails 7.0+ with mysql2 adapter

### Internal Dependencies
- Phase 1 adapter infrastructure (complete)
- BaseAdapter interface
- Registry with adapter detection
- Configuration with MysqlConfig
- Introspection delegation
- Generator adapter awareness

### Integration App Dependencies
- MySQL Docker service
- MySQL-compatible migrations
- mysql2 gem in integration app
- Modified schema for MySQL limitations

## Migration Path

### Step 1: Implement MysqlAdapter Core
- Create adapter class
- Implement introspection queries
- Return normalized data structures

### Step 2: Implement MySQL SQL Generation
- Implement generate_* methods
- Test SQL syntax validity
- Handle MySQL-specific features

### Step 3: Create MySQL Integration App
- Copy integration/ structure
- Adapt migrations for MySQL
- Configure docker-compose for MySQL
- Test database creation and seeding

### Step 4: Integration Testing
- Test full dump workflow
- Test schema load workflow
- Test version storage
- Test multi-file output

### Step 5: Documentation and Examples
- Update README with MySQL instructions
- Document type mappings
- Document feature limitations
- Provide migration examples

## Performance Targets

- 100 tables: < 10 seconds (MySQL information_schema is slower)
- 500 tables: < 30 seconds
- Memory usage: < 150MB increase
- Deterministic output: 100% identical on repeated dumps
- Query efficiency: Minimize information_schema queries

## Keywords

MySQL adapter implementation, mysql2 gem integration, information_schema queries, MySQL system tables, MySQL SQL dialect, CREATE TABLE MySQL syntax, AUTO_INCREMENT handling, MySQL indexes BTREE HASH FULLTEXT, MySQL foreign keys, ALTER TABLE ADD CONSTRAINT, MySQL views, CREATE VIEW ALGORITHM, MySQL triggers, CREATE TRIGGER timing, MySQL stored procedures, CREATE PROCEDURE delimiter, MySQL routines, information_schema.ROUTINES, MySQL type mapping, ENUM inline definition, SET type, JSON columns, composite type to JSON, array to JSON, SERIAL to AUTO_INCREMENT, UUID to CHAR(36), BYTEA to BLOB, TIMESTAMP to DATETIME, utf8mb4 encoding, utf8mb4_unicode_ci collation, MySQL 8.0 features, check constraints MySQL 8.0.16, MySQL version detection, MysqlConfig settings, integration_mysql app, MySQL-compatible migrations, docker-compose MySQL service, mysql:8.0-alpine image, MySQL health check, mysqladmin ping, feature parity 80%, PostgreSQL to MySQL migration, type conversion, delimiter changes procedures, reserved keywords MySQL, AUTO_INCREMENT gaps, circular dependencies foreign keys, view dependencies, mysqldump comparison, deterministic MySQL dump, schema versioning MySQL, multi-file output MySQL, performance targets MySQL, information_schema performance
