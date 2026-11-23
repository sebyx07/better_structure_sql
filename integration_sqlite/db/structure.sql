CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "users" (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        encrypted_password TEXT,
        uuid TEXT,
        role TEXT NOT NULL DEFAULT 'user' CHECK(role IN ('admin', 'user', 'guest')),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
CREATE UNIQUE INDEX "index_users_on_email" ON "users" ("email");
CREATE INDEX "index_users_on_uuid" ON "users" ("uuid");
CREATE TABLE IF NOT EXISTS "posts" (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT,
        status TEXT DEFAULT 'draft',
        tags TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );
CREATE INDEX "index_posts_on_user_id" ON "posts" ("user_id");
CREATE INDEX "index_posts_on_status" ON "posts" ("status");
CREATE TABLE IF NOT EXISTS "comments" (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        post_id INTEGER,
        user_id INTEGER,
        body TEXT,
        parent_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
        FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE
      );
CREATE INDEX "index_comments_on_post_id" ON "comments" ("post_id");
CREATE INDEX "index_comments_on_user_id" ON "comments" ("user_id");
CREATE INDEX "index_comments_on_parent_id" ON "comments" ("parent_id");
CREATE TABLE IF NOT EXISTS "products" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "description" text, "price" decimal(10,2), "stock_quantity" integer DEFAULT 0, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE INDEX "index_products_on_name" ON "products" ("name");
CREATE VIEW user_stats AS
SELECT
  u.id,
  u.email,
  COUNT(DISTINCT p.id) AS post_count,
  COUNT(DISTINCT c.id) AS comment_count
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
LEFT JOIN comments c ON c.user_id = u.id
GROUP BY u.id, u.email
/* user_stats(id,email,post_count,comment_count) */
/* user_stats(id,email,post_count,comment_count) */
/* user_stats(id,email,post_count,comment_count) */
/* user_stats(id,email,post_count,comment_count) */;
CREATE TRIGGER update_posts_updated_at
AFTER UPDATE ON posts
FOR EACH ROW
BEGIN
  UPDATE posts
  SET updated_at = datetime('now')
  WHERE id = NEW.id;
END;
CREATE TRIGGER update_post_comment_count
AFTER INSERT ON comments
FOR EACH ROW
BEGIN
  UPDATE posts
  SET updated_at = datetime('now')
  WHERE id = NEW.post_id;
END;
CREATE TABLE IF NOT EXISTS "better_structure_sql_schema_versions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "content" text NOT NULL, "sqlite_version" varchar, "format_type" varchar DEFAULT 'sql', "zip_archive" blob, "output_mode" varchar DEFAULT 'single_file', "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "content_hash" varchar(32) NOT NULL);
CREATE INDEX "index_better_structure_sql_schema_versions_on_created_at" ON "better_structure_sql_schema_versions" ("created_at");
CREATE INDEX "index_better_structure_sql_schema_versions_on_content_hash" ON "better_structure_sql_schema_versions" ("content_hash");
CREATE TABLE regions (
  code TEXT NOT NULL,
  country TEXT NOT NULL,
  name TEXT COLLATE NOCASE,
  PRIMARY KEY (code, country)
) WITHOUT ROWID
;
CREATE TABLE ledger_entries (
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
CREATE TABLE settings (key TEXT PRIMARY KEY, value ANY, version INTEGER NOT NULL) STRICT;
CREATE INDEX idx_ledger_positive ON ledger_entries (region_code) WHERE amount > 0;
CREATE UNIQUE INDEX idx_ledger_lower_note ON ledger_entries (lower(note), quantity DESC);
INSERT INTO "schema_migrations" (version) VALUES
('20250201000001'),
('20250120000001'),
('20250101000006'),
('20250101000005'),
('20250101000004'),
('20250101000003'),
('20250101000002'),
('20250101000001');

