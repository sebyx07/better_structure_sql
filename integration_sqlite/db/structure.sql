PRAGMA foreign_keys = ON;
PRAGMA defer_foreign_keys = ON;

-- PRAGMAs
PRAGMA foreign_keys = 1;
PRAGMA recursive_triggers = 0;
PRAGMA defer_foreign_keys = 0;
PRAGMA journal_mode = 'wal';
PRAGMA synchronous = 1;
PRAGMA temp_store = 0;
PRAGMA locking_mode = 'normal';
PRAGMA auto_vacuum = 0;
PRAGMA cache_size = 2000;

-- Tables

CREATE TABLE better_structure_sql_schema_versions (
  id integer,
  content text NOT NULL,
  sqlite_version text,
  format_type text DEFAULT 'sql',
  zip_archive blob,
  output_mode text DEFAULT 'single_file',
  created_at DATETIME NOT NULL DEFAULT datetime('now'),
  updated_at DATETIME NOT NULL DEFAULT datetime('now'),
  PRIMARY KEY (id)
);

CREATE TABLE comments (
  id integer,
  post_id integer,
  user_id integer,
  body text,
  parent_id integer,
  created_at text NOT NULL DEFAULT datetime('now'),
  updated_at text NOT NULL DEFAULT datetime('now'),
  PRIMARY KEY (id),
  FOREIGN KEY (parent_id) REFERENCES comments (id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL,
  FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE
);

CREATE TABLE posts (
  id integer,
  user_id integer NOT NULL,
  title text NOT NULL,
  content text,
  status text DEFAULT 'draft',
  tags text,
  metadata text,
  created_at text NOT NULL DEFAULT datetime('now'),
  updated_at text NOT NULL DEFAULT datetime('now'),
  PRIMARY KEY (id),
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE products (
  id integer,
  name text NOT NULL,
  description text,
  price DECIMAL(10,2),
  stock_quantity integer DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT datetime('now'),
  updated_at DATETIME NOT NULL DEFAULT datetime('now'),
  PRIMARY KEY (id)
);

CREATE TABLE users (
  id integer,
  email text NOT NULL,
  encrypted_password text,
  uuid text,
  role text NOT NULL DEFAULT 'user',
  created_at text NOT NULL DEFAULT datetime('now'),
  updated_at text NOT NULL DEFAULT datetime('now'),
  PRIMARY KEY (id)
);

-- Indexes
CREATE INDEX "index_better_structure_sql_schema_versions_on_created_at" ON "better_structure_sql_schema_versions" ("created_at");
CREATE INDEX "index_comments_on_parent_id" ON "comments" ("parent_id");
CREATE INDEX "index_comments_on_user_id" ON "comments" ("user_id");
CREATE INDEX "index_comments_on_post_id" ON "comments" ("post_id");
CREATE INDEX "index_posts_on_status" ON "posts" ("status");
CREATE INDEX "index_posts_on_user_id" ON "posts" ("user_id");
CREATE INDEX "index_products_on_name" ON "products" ("name");
CREATE INDEX "index_users_on_uuid" ON "users" ("uuid");
CREATE UNIQUE INDEX "index_users_on_email" ON "users" ("email");

-- Views

CREATE VIEW user_stats AS
SELECT
  u.id,
  u.email,
  COUNT(DISTINCT p.id) AS post_count,
  COUNT(DISTINCT c.id) AS comment_count
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
LEFT JOIN comments c ON c.user_id = u.id
GROUP BY u.id, u.email;

-- Triggers

CREATE TRIGGER update_post_comment_count
AFTER INSERT ON comments
FOR EACH ROW
BEGIN
  UPDATE posts
  SET updated_at = datetime('now')
  WHERE id = NEW.post_id;
END;

CREATE TRIGGER update_posts_updated_at
AFTER UPDATE ON posts
FOR EACH ROW
BEGIN
  UPDATE posts
  SET updated_at = datetime('now')
  WHERE id = NEW.id;
END;

-- Schema Migrations
INSERT INTO "schema_migrations" (version) VALUES
('20250101000001'),
('20250101000002'),
('20250101000003'),
('20250101000004'),
('20250101000005'),
('20250101000006')
ON CONFLICT DO NOTHING;