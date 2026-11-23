CREATE TABLE "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);

CREATE TABLE "better_structure_sql_schema_versions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "content" text NOT NULL, "sqlite_version" varchar, "format_type" varchar DEFAULT 'sql', "zip_archive" blob, "output_mode" varchar DEFAULT 'single_file', "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "content_hash" varchar(32) NOT NULL);

CREATE TABLE "comments" (
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

CREATE TABLE "posts" (
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

CREATE TABLE "products" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "description" text, "price" decimal(10,2), "stock_quantity" integer DEFAULT 0, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);

CREATE TABLE regions (
  code TEXT NOT NULL,
  country TEXT NOT NULL,
  name TEXT COLLATE NOCASE,
  PRIMARY KEY (code, country)
) WITHOUT ROWID
;

CREATE TABLE "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);

CREATE TABLE settings (key TEXT PRIMARY KEY, value ANY, version INTEGER NOT NULL) STRICT;

CREATE TABLE "users" (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        encrypted_password TEXT,
        uuid TEXT,
        role TEXT NOT NULL DEFAULT 'user' CHECK(role IN ('admin', 'user', 'guest')),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
