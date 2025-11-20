CREATE TABLE IF NOT EXISTS better_structure_sql_schema_versions (
  "id" integer NOT NULL,
  "content" text NOT NULL,
  "sqlite_version" text,
  "format_type" text DEFAULT 'sql',
  "zip_archive" blob,
  "output_mode" text DEFAULT 'single_file',
  "created_at" datetime(6) NOT NULL,
  "updated_at" datetime(6) NOT NULL,
  "content_hash" text NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS comments (
  "id" integer,
  "post_id" integer,
  "user_id" integer,
  "body" text,
  "parent_id" integer,
  "created_at" text NOT NULL,
  "updated_at" text NOT NULL,
  PRIMARY KEY ("id"),
  FOREIGN KEY (parent_id) REFERENCES comments (id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL,
  FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS posts (
  "id" integer,
  "user_id" integer NOT NULL,
  "title" text NOT NULL,
  "content" text,
  "status" text DEFAULT 'draft',
  "tags" text,
  "metadata" text,
  "created_at" text NOT NULL,
  "updated_at" text NOT NULL,
  PRIMARY KEY ("id"),
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS products (
  "id" integer NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "price" decimal(10,2),
  "stock_quantity" integer DEFAULT 0,
  "created_at" datetime(6) NOT NULL,
  "updated_at" datetime(6) NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS users (
  "id" integer,
  "email" text NOT NULL,
  "encrypted_password" text,
  "uuid" text,
  "role" text NOT NULL DEFAULT 'user',
  "created_at" text NOT NULL,
  "updated_at" text NOT NULL,
  PRIMARY KEY ("id")
);
