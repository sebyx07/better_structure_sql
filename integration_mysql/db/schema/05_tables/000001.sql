CREATE TABLE IF NOT EXISTS ar_internal_metadata (
  `key` varchar(255) NOT NULL,
  `value` varchar(255),
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`key`)
);

CREATE TABLE IF NOT EXISTS better_structure_sql_schema_versions (
  `id` bigint NOT NULL,
  `content` text NOT NULL,
  `zip_archive` longblob,
  `pg_version` varchar(255) NOT NULL,
  `format_type` varchar(255) NOT NULL,
  `output_mode` varchar(255) NOT NULL,
  `content_size` bigint NOT NULL,
  `line_count` int NOT NULL,
  `file_count` int,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `content_hash` varchar(32) NOT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS categories (
  `id` bigint NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  `slug` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS order_items (
  `id` bigint NOT NULL,
  `order_id` bigint,
  `product_id` bigint,
  `quantity` int NOT NULL DEFAULT 1,
  `price` decimal(10,2) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS orders (
  `id` bigint NOT NULL,
  `user_id` bigint,
  `total` decimal(10,2) NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'pending',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS posts (
  `id` bigint NOT NULL,
  `title` varchar(255) NOT NULL,
  `body` text,
  `user_id` bigint,
  `status` varchar(255) DEFAULT 'draft',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS products (
  `id` bigint NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  `price` decimal(10,2) NOT NULL,
  `stock_quantity` int NOT NULL DEFAULT 0,
  `category_id` bigint,
  `metadata` json,
  `tags` json,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS schema_migrations (
  `version` varchar(255) NOT NULL,
  PRIMARY KEY (`version`)
);

CREATE TABLE IF NOT EXISTS users (
  `id` bigint NOT NULL,
  `email` varchar(255) NOT NULL,
  `encrypted_password` varchar(255),
  `uuid` varchar(36),
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
);
