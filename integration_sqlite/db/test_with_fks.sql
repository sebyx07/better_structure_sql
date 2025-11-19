-- SQLite database with foreign keys enabled
PRAGMA foreign_keys=ON;

CREATE TABLE better_structure_sql_schema_versions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  content TEXT NOT NULL,
  sqlite_version VARCHAR,
  format_type VARCHAR DEFAULT 'sql',
  zip_archive BLOB,
  output_mode VARCHAR DEFAULT 'single_file',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);
CREATE INDEX index_better_structure_sql_schema_versions_on_created_at
  ON better_structure_sql_schema_versions(created_at);

CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL,
  encrypted_password TEXT,
  uuid TEXT,
  role TEXT NOT NULL DEFAULT 'user' CHECK(role IN ('admin', 'user', 'guest')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE UNIQUE INDEX index_users_on_email ON users(email);
CREATE INDEX index_users_on_uuid ON users(uuid);

CREATE TABLE posts (
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
CREATE INDEX index_posts_on_user_id ON posts(user_id);
CREATE INDEX index_posts_on_status ON posts(status);

CREATE TABLE comments (
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
CREATE INDEX index_comments_on_post_id ON comments(post_id);
CREATE INDEX index_comments_on_user_id ON comments(user_id);
CREATE INDEX index_comments_on_parent_id ON comments(parent_id);

CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2),
  stock_quantity INTEGER DEFAULT 0,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);
CREATE INDEX index_products_on_name ON products(name);

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

-- Schema migrations
CREATE TABLE IF NOT EXISTS schema_migrations (version varchar NOT NULL PRIMARY KEY);
INSERT INTO schema_migrations (version) VALUES
('20250101000001'),
('20250101000002'),
('20250101000003'),
('20250101000004'),
('20250101000005'),
('20250101000006');

CREATE TABLE IF NOT EXISTS ar_internal_metadata (
  key varchar NOT NULL PRIMARY KEY,
  value varchar,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL
);
INSERT INTO ar_internal_metadata VALUES('environment','development',datetime('now'),datetime('now'));
