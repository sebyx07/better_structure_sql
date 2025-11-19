# Multi-File Schema Output - Usage Guide

## When to Use Multi-File Output

Use multi-file output when:
- Schema exceeds 10,000 lines
- More than 1,000 database objects
- Single file causes editor performance issues
- Team needs to review schema changes frequently
- Git diffs are too large to be useful

## Configuration

### Basic Setup

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  # Multi-file output (directory path)
  config.output_path = 'db/schema'
end
```

### Advanced Options

```ruby
BetterStructureSql.configure do |config|
  config.output_path = 'db/schema'

  # Adjust chunk size
  config.max_lines_per_file = 500        # Default: 500
  config.overflow_threshold = 1.1        # Default: 1.1 (10%)

  # Manifest generation
  config.generate_manifest = true        # Default: true

  # Versioning with ZIP storage
  config.enable_schema_versions = true
  config.schema_versions_limit = 10
end
```

## Directory Structure

### Numbered Directories

Directories are prefixed with numbers indicating load order:

1. `01_extensions/` - PostgreSQL extensions
2. `02_types/` - Custom types (enums, composites, domains)
3. `03_functions/` - User-defined functions
4. `04_sequences/` - Sequences
5. `05_tables/` - Tables with columns and constraints
6. `06_indexes/` - Indexes
7. `07_foreign_keys/` - Foreign key constraints
8. `08_views/` - Views and materialized views
9. `09_triggers/` - Triggers
10. `10_migrations/` - Schema migrations table

### File Naming

Files within directories: `000001.sql`, `000002.sql`, etc.

Example:
```
db/schema/
├── _header.sql
├── _manifest.json
├── 01_extensions/
│   └── 000001.sql
├── 02_types/
│   ├── 000001.sql
│   └── 000002.sql
├── 05_tables/
│   ├── 000001.sql  (users, posts, comments - ~500 LOC)
│   ├── 000002.sql  (orders, products - ~500 LOC)
│   └── 000003.sql  (large_table with 600 columns - 800 LOC OK)
├── 06_indexes/
│   └── 000001.sql
└── 10_migrations/
    └── 000001.sql
```

### Special Files

- `_header.sql` - SET statements and search path
- `_manifest.json` - Metadata and load order

## Chunking Behavior

### 500 LOC Soft Limit

Files target 500 lines with 10% overflow tolerance (550 lines):

**Scenario 1**: Accumulate small objects
```
Current: 450 lines
Next object: 40 lines
Total: 490 lines (under 550 threshold)
→ Add to current file
```

**Scenario 2**: Overflow triggers new file
```
Current: 450 lines
Next object: 120 lines
Total: 570 lines (over 550 threshold)
→ New file for object
```

**Scenario 3**: Large single object
```
Next object: 650 lines (huge table)
→ Dedicated file (OK to exceed limit)
```

### Why 500 Lines?

- Easy to review in pull requests
- Fast to load in editors
- Good git diff granularity
- Balance between file count and file size

## Dumping Schema

### Command

```bash
rails db:schema:dump
```

Or explicitly:

```bash
rails db:schema:dump_better
```

### Output

```
Schema dumped to db/schema
Total files: 12
Total size: 74.01 KB
```

### Verify

```bash
ls -R db/schema
cat db/schema/_manifest.json | jq .
```

## Loading Schema

### Command

```bash
rails db:schema:load
```

Or explicitly:

```bash
rails db:schema:load_better
```

### How It Works

1. Detects directory mode automatically
2. Reads `_header.sql` first
3. Loads numbered directories in order
4. Concatenates files within each directory
5. Executes SQL

### Manual Load

```bash
# Load header
psql -d myapp_development -f db/schema/_header.sql

# Load sections in order
for dir in db/schema/0*; do
  cat $dir/*.sql | psql -d myapp_development
done
```

## Schema Versioning

### Store Current Schema

```bash
rails db:schema:store
```

Stores both:
- Combined content (all SQL concatenated)
- ZIP archive (complete directory structure)
- Manifest embedded in content

### List Versions

```bash
rails db:schema:versions
```

Output:
```
Total versions: 2

ID     Format  Mode          Files   PostgreSQL      Created              Size
-----------------------------------------------------------------------------------------------
2      sql     single_file   1       15.15           2025-11-19 06:41:20  73.95 KB
1      sql     multi_file    12      15.15           2025-11-19 06:41:06  74.94 KB
```

### Restore Version

```bash
rails db:schema:restore[1]
```

Process for multi-file versions:
1. Extracts ZIP to temp directory
2. Loads files in manifest order
3. Cleans up temp directory

Process for single-file versions:
1. Executes content directly

## Web UI

### Access

Navigate to: `http://localhost:3000/better_structure_sql/schema_versions`

(Mount point configurable in routes)

### Features

**Index Page**:
- List all stored versions
- See file counts and sizes
- Output mode badges (Multi-File / Single File)
- One-click download

**Show Page**:
- View metadata (format, mode, PG version, created)
- See directory list for multi-file versions
- View combined content (if < 200 KB)
- Download button

**Download**:
- Multi-file: Downloads ZIP archive
- Single-file: Downloads text file
- Large files: Streams efficiently

### Authentication

Add authentication in your routes:

```ruby
# config/routes.rb
authenticate :user, ->(user) { user.admin? } do
  mount BetterStructureSql::Engine, at: '/better_structure_sql'
end
```

## Git Workflow

### Initial Setup

```bash
# Configure multi-file output
# Edit config/initializers/better_structure_sql.rb:
#   config.output_path = 'db/schema'

# Dump multi-file schema
rails db:schema:dump

# Add to git
git add db/schema/
git rm db/structure.sql  # If migrating from single file
git commit -m "Switch to multi-file schema output"
```

### Making Changes

```bash
# Make schema changes
rails generate migration AddUsersTable

# Run migration
rails db:migrate

# Dump schema (happens automatically if replace_default_dump = true)
rails db:schema:dump

# Review changes
git status  # Shows only affected files
git diff db/schema/

# Commit
git add db/schema/
git commit -m "Add users table"
```

### Code Review

Reviewer sees only changed files:
```
modified: db/schema/05_tables/000002.sql  (added users table)
modified: db/schema/06_indexes/000001.sql (added index)
modified: db/schema/_manifest.json        (updated stats)
```

Much cleaner than 50,000 line structure.sql diff!

## Troubleshooting

### Issue: "Manifest not found"

**Cause**: Directory missing `_manifest.json`

**Solution**:
```bash
# Re-dump schema
rails db:schema:dump
```

### Issue: Files in wrong order

**Cause**: Manual file modification

**Solution**:
```bash
# Dump fresh schema
rm -rf db/schema/
rails db:schema:dump
```

### Issue: Large file exceeds 500 LOC

**Answer**: This is OK! Single large objects (600+ column table, complex function) get dedicated files. The 500 LOC is a soft limit with 10% overflow tolerance.

### Issue: Want larger chunks

**Solution**:
```ruby
# config/initializers/better_structure_sql.rb
config.max_lines_per_file = 1000  # Increase limit
config.overflow_threshold = 1.2    # 20% overflow
```

### Issue: Too many files

**Symptoms**: Git operations slow, > 500 files

**Solutions**:
1. Increase `max_lines_per_file`
2. Disable unused features:
```ruby
config.include_functions = false  # If not using stored procedures
config.include_triggers = false   # If not using triggers
```

## Performance Tips

### Large Schemas (10,000+ tables)

**Configuration**:
```ruby
config.max_lines_per_file = 1000  # Reduce file count
config.include_comments = false   # Skip if not needed
```

**Memory**: Multi-file output uses constant memory regardless of schema size (writes incrementally).

**Speed**: Expect ~60 seconds for 10,000 tables.

### Git Performance

- Keep file counts < 500 for good git performance
- Use larger `max_lines_per_file` if needed
- Regular cleanup of old schema versions:
```bash
rails db:schema:cleanup
```

### Editor Performance

- 500 LOC files load instantly in all editors
- Easy to search and navigate
- Syntax highlighting works well

## Migration from Single File

### Step 1: Update Configuration

```ruby
# config/initializers/better_structure_sql.rb

# Before
config.output_path = 'db/structure.sql'

# After
config.output_path = 'db/schema'
```

### Step 2: Dump

```bash
rails db:schema:dump
```

### Step 3: Verify

```bash
ls -R db/schema
cat db/schema/_manifest.json | jq .
```

### Step 4: Test Load

```bash
# Fresh database
rails db:drop db:create

# Load multi-file
rails db:schema:load

# Verify tables
rails console
> ActiveRecord::Base.connection.tables.count
```

### Step 5: Commit

```bash
git add db/schema/
git rm db/structure.sql
git commit -m "Migrate to multi-file schema output"
```

### Rollback (if needed)

```ruby
# config/initializers/better_structure_sql.rb
config.output_path = 'db/structure.sql'
```

```bash
rails db:schema:dump
git rm -rf db/schema/
git add db/structure.sql
git commit -m "Revert to single-file schema"
```

## Best Practices

### 1. Keep Manifest

Always commit `_manifest.json` with schema files. It provides:
- Load order
- File counts and statistics
- Version information

### 2. Regular Versioning

Store schema versions after major changes:
```bash
rails db:schema:store
```

### 3. Cleanup Old Versions

Configure retention limit:
```ruby
config.schema_versions_limit = 10  # Keep last 10
```

Or manual cleanup:
```bash
rails db:schema:cleanup
```

### 4. Review Changes

Before committing:
```bash
git diff db/schema/ | less
```

### 5. Use Web UI

For downloading and comparing versions:
```
http://localhost:3000/better_structure_sql/schema_versions
```

## Advanced Usage

### Custom Output Path

```ruby
config.output_path = 'custom/path/to/schema'
```

### Environment-Specific Config

```ruby
if Rails.env.production?
  config.enable_schema_versions = false  # Don't store in production
elsif Rails.env.development?
  config.schema_versions_limit = 20     # Keep more in development
end
```

### Disable Multi-File

Temporarily switch to single-file:

```ruby
# Use structure.sql for this dump
config.output_path = 'db/structure.sql'
```

```bash
rails db:schema:dump
```

Then switch back to multi-file.

## FAQ

**Q: Does multi-file work with schema.rb?**

A: No, multi-file is for SQL format only. Use `config.output_path = 'db/structure.sql'` or `'db/schema'` (directory).

**Q: Can I mix single-file and multi-file?**

A: Yes! The loader auto-detects. You can switch between them by changing `output_path`.

**Q: What about MySQL/SQLite?**

A: Currently PostgreSQL only. Multi-database support planned for future.

**Q: Does this work with Rails < 7.0?**

A: Minimum Rails 7.0 required.

**Q: How do I authenticate the Web UI?**

A: Use route constraints (see Web UI section above) or controller-level auth.

**Q: Can I customize directory names?**

A: Directory names are fixed to ensure correct load order. Customize via `max_lines_per_file` instead.

**Q: What if I delete files manually?**

A: Run `rails db:schema:dump` to regenerate. Don't edit multi-file output manually.

**Q: How do I diff two versions?**

A: Use Web UI or extract ZIPs and diff directories:
```bash
# Download version 1 and 2 ZIPs from Web UI
unzip version_1.zip -d v1/
unzip version_2.zip -d v2/
diff -r v1/ v2/
```

## Support

**Issues**: https://github.com/yourusername/better_structure_sql/issues

**Docs**: https://github.com/yourusername/better_structure_sql

**Questions**: Open a discussion on GitHub
