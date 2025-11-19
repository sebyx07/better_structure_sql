SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

SET search_path TO "$user", public;

SET default_tablespace = '';

SET default_table_access_method = heap;

-- Tables

CREATE TABLE better_structure_sql_schema_versions (
  id integer NOT NULL,
  content text NOT NULL,
  sqlite_version text,
  format_type text DEFAULT 'sql',
  zip_archive blob,
  output_mode text DEFAULT 'single_file',
  created_at datetime(6) NOT NULL,
  updated_at datetime(6) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE comments (
  id integer,
  post_id integer,
  user_id integer,
  body text,
  parent_id integer,
  created_at text NOT NULL,
  updated_at text NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE posts (
  id integer,
  user_id integer NOT NULL,
  title text NOT NULL,
  content text,
  status text DEFAULT 'draft',
  tags text,
  metadata text,
  created_at text NOT NULL,
  updated_at text NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE products (
  id integer NOT NULL,
  name text NOT NULL,
  description text,
  price decimal(10,2),
  stock_quantity integer DEFAULT 0,
  created_at datetime(6) NOT NULL,
  updated_at datetime(6) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE users (
  id integer,
  email text NOT NULL,
  encrypted_password text,
  uuid text,
  role text NOT NULL DEFAULT 'user',
  created_at text NOT NULL,
  updated_at text NOT NULL,
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

-- Foreign Keys
ALTER TABLE comments ADD CONSTRAINT fk_comments_comments_parent_id FOREIGN KEY (parent_id) REFERENCES comments (id) ON DELETE CASCADE;
ALTER TABLE comments ADD CONSTRAINT fk_comments_users_user_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL;
ALTER TABLE comments ADD CONSTRAINT fk_comments_posts_post_id FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE;
ALTER TABLE posts ADD CONSTRAINT fk_posts_users_user_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE;

-- Views

CREATE VIEW main.user_stats AS
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