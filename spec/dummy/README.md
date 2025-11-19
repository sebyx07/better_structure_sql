# Dummy Rails Application

Complex Rails application for testing BetterStructureSql gem with comprehensive PostgreSQL features.

## Purpose

Test schema dumping with real-world complexity including:
- Multiple PostgreSQL extensions
- Custom types and enums
- Complex table relationships
- Views and materialized views
- Functions and triggers
- Partitioned tables
- Inherited tables
- Various index types

## Schema Overview

### Extensions
- `pgcrypto` - Cryptographic functions
- `uuid-ossp` - UUID generation
- `pg_trgm` - Trigram matching for full-text search
- `hstore` - Key-value storage
- `citext` - Case-insensitive text

### Custom Types

**Enums:**
- `user_role` - admin, moderator, user, guest
- `order_status` - pending, processing, shipped, delivered, cancelled
- `payment_method` - credit_card, debit_card, paypal, stripe, bank_transfer

**Domains:**
- `email` - varchar(255) with email validation
- `url` - varchar(2048) with URL validation
- `phone_number` - varchar(20) with phone format validation
- `positive_integer` - integer > 0

### Tables

#### Core Tables

**users** - User accounts with UUID primary key
- Extensions: pgcrypto for password hashing
- Columns: id (uuid), email (domain), role (enum), profile (jsonb), settings (hstore)
- Indexes: unique email, gin on jsonb, btree on role

**organizations** - Multi-tenant organizations
- Columns: id, name, slug, metadata (jsonb), created_at, updated_at
- Indexes: unique slug, gin on metadata

**memberships** - User-organization relationships
- Foreign keys: user_id, organization_id with CASCADE
- Unique index on [user_id, organization_id]

#### E-commerce Tables

**products** - Product catalog
- Columns: id, name, description, price (decimal), tags (text[]), search_vector (tsvector)
- Indexes: gin on tags array, gin on tsvector for full-text search
- Check constraint: price > 0

**categories** - Product categories with inheritance
- Self-referential foreign key for parent_id
- Trigger to update updated_at

**orders** - Customer orders (partitioned by created_at)
- Partition by RANGE on created_at (monthly partitions)
- Columns: id, user_id, status (enum), total (decimal), metadata (jsonb)
- Foreign key to users

**order_items** - Order line items
- Foreign keys: order_id, product_id
- Check constraint: quantity > 0, price >= 0

#### Audit Tables

**audit_logs** - Inherited audit table pattern
- Base table with common audit columns
- Child tables: user_audits, order_audits, product_audits
- Trigger function to populate created_at

### Views

**active_users** - Users who logged in within 30 days
```sql
SELECT * FROM users WHERE last_login_at > NOW() - INTERVAL '30 days'
```

**order_summaries** - Aggregate order data
```sql
SELECT
  user_id,
  COUNT(*) as order_count,
  SUM(total) as total_spent
FROM orders
GROUP BY user_id
```

**product_search** - Searchable product view with rankings
```sql
SELECT
  p.*,
  ts_rank(search_vector, query) as rank
FROM products p, plainto_tsquery('english', search_term) query
WHERE search_vector @@ query
```

### Materialized Views

**user_statistics** - Aggregated user stats (refreshed daily)
- Columns: user_id, order_count, total_spent, avg_order_value, last_order_at
- Indexes: unique on user_id, btree on total_spent

**daily_revenue** - Daily revenue rollup
- Partition by created_at date
- Indexes on date and revenue amount

### Functions

**update_updated_at_column()** - Trigger function
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**calculate_order_total(order_id)** - Calculate order total
```sql
CREATE OR REPLACE FUNCTION calculate_order_total(p_order_id bigint)
RETURNS decimal AS $$
  SELECT SUM(quantity * price) FROM order_items WHERE order_id = p_order_id;
$$ LANGUAGE sql STABLE;
```

**search_products(query text)** - Full-text product search
```sql
CREATE OR REPLACE FUNCTION search_products(query text)
RETURNS TABLE(product_id bigint, name varchar, rank real) AS $$
  SELECT id, name, ts_rank(search_vector, plainto_tsquery('english', query))
  FROM products
  WHERE search_vector @@ plainto_tsquery('english', query)
  ORDER BY ts_rank DESC;
$$ LANGUAGE sql STABLE;
```

**audit_changes()** - Generic audit trigger
```sql
CREATE OR REPLACE FUNCTION audit_changes()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (table_name, record_id, action, old_data, new_data)
  VALUES (TG_TABLE_NAME, NEW.id, TG_OP, row_to_json(OLD), row_to_json(NEW));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Triggers

**users_updated_at_trigger**
- BEFORE UPDATE ON users
- FOR EACH ROW
- EXECUTE FUNCTION update_updated_at_column()

**categories_updated_at_trigger**
- BEFORE UPDATE ON categories
- FOR EACH ROW
- EXECUTE FUNCTION update_updated_at_column()

**products_search_vector_trigger**
- BEFORE INSERT OR UPDATE ON products
- FOR EACH ROW
- Update tsvector from name and description

**audit_trigger_users**
- AFTER INSERT OR UPDATE OR DELETE ON users
- FOR EACH ROW
- EXECUTE FUNCTION audit_changes()

### Indexes

**Unique Indexes:**
- users(email)
- organizations(slug)
- memberships(user_id, organization_id)

**Multi-column Indexes:**
- orders(user_id, status, created_at)
- order_items(order_id, product_id)

**Partial Indexes:**
- products(price) WHERE price > 100
- users(email) WHERE deleted_at IS NULL

**Expression Indexes:**
- LOWER(users.email)
- UPPER(organizations.name)

**GIN Indexes:**
- products(tags) - array search
- products(search_vector) - full-text search
- users(profile) - jsonb search
- users(settings) - hstore search

**GiST Indexes:**
- products using gist(search_vector)

### Foreign Keys

**With CASCADE:**
- order_items.order_id → orders.id ON DELETE CASCADE
- memberships.user_id → users.id ON DELETE CASCADE
- memberships.organization_id → organizations.id ON DELETE CASCADE

**With SET NULL:**
- products.category_id → categories.id ON DELETE SET NULL

**With RESTRICT:**
- orders.user_id → users.id ON DELETE RESTRICT

### Check Constraints

- products.price > 0
- order_items.quantity > 0
- order_items.price >= 0
- users.email matches email pattern
- orders.total >= 0

### Partitioned Tables

**orders** - Range partitioned by created_at
- orders_2024_01 FOR VALUES FROM ('2024-01-01') TO ('2024-02-01')
- orders_2024_02 FOR VALUES FROM ('2024-02-01') TO ('2024-03-01')
- orders_2024_03 FOR VALUES FROM ('2024-03-01') TO ('2024-04-01')

**measurements** - Range partitioned by timestamp
- measurements_default DEFAULT PARTITION

### Inherited Tables

**audit_logs** (base table)
- user_audits INHERITS (audit_logs)
- order_audits INHERITS (audit_logs)
- product_audits INHERITS (audit_logs)

## Database Setup

```bash
cd spec/dummy
rails db:create
rails db:migrate
rails db:seed
```

## Generate Schema

```bash
# Using pg_dump (default Rails)
rails db:schema:dump

# Using BetterStructureSql
rails db:schema:dump_better

# Compare outputs
diff db/structure_pg_dump.sql db/structure_better.sql
```

## Testing

Run specs that compare pg_dump vs BetterStructureSql output:

```bash
rspec spec/integration/schema_comparison_spec.rb
```

## Seed Data

Generates test data:
- 100 users with various roles
- 50 organizations
- 200 memberships
- 500 products across 20 categories
- 1000 orders with 3000+ order items
- Partitioned across 3 months

## Schema Complexity Metrics

- Tables: 15+
- Indexes: 30+
- Foreign Keys: 10+
- Views: 3
- Materialized Views: 2
- Functions: 5+
- Triggers: 5+
- Extensions: 5
- Custom Types: 7+
- Partitions: 3+
- Inherited Tables: 3

Total database objects: 80+

## Performance Testing

Measure dumper performance:

```ruby
require 'benchmark'

Benchmark.bm do |x|
  x.report("pg_dump:") { system("pg_dump --schema-only > /dev/null") }
  x.report("better_sql:") { BetterStructureSql::Dumper.dump }
end
```

## Schema Validation

Compare structure.sql outputs:

```bash
# Generate both
pg_dump --schema-only > /tmp/pg_dump.sql
rails db:schema:dump_better

# Normalize and compare
./scripts/normalize_schema.rb /tmp/pg_dump.sql > /tmp/pg_normalized.sql
./scripts/normalize_schema.rb db/structure.sql > /tmp/better_normalized.sql
diff /tmp/pg_normalized.sql /tmp/better_normalized.sql
```

## Maintenance

Update schema complexity:

```bash
rails db:migrate
rails db:seed
rails db:schema:dump_better
```
