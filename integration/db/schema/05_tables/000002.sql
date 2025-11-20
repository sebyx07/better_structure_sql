CREATE TABLE IF NOT EXISTS large_table_030 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_030_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  "related_id" bigint,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_030_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_031 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_031_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_031_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_032 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_032_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  "related_id" bigint,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_032_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_033 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_033_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_033_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_034 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_034_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  "related_id" bigint,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_034_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_035 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_035_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_035_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_036 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_036_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  "related_id" bigint,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_036_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_037 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_037_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_037_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_038 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_038_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  "related_id" bigint,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_038_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_039 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_039_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_039_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_040 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_040_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  "related_id" bigint,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_040_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_041 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_041_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_041_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_042 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_042_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  "related_id" bigint,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_042_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_043 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_043_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_043_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_044 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_044_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  "related_id" bigint,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_044_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_045 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_045_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_045_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_046 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_046_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  "related_id" bigint,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_046_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_047 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_047_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_047_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_048 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_048_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  "related_id" bigint,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_048_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_049 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_049_id_seq'::regclass),
  "name" varchar NOT NULL,
  "description" text,
  "status" integer DEFAULT 0,
  "price" numeric(10,2),
  "active" boolean DEFAULT true,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "external_id" uuid,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT chk_large_table_049_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS order_items (
  "id" bigint NOT NULL DEFAULT nextval('order_items_id_seq'::regclass),
  "order_id" bigint NOT NULL,
  "product_id" bigint NOT NULL,
  "quantity" integer NOT NULL,
  "unit_price" numeric(10,2) NOT NULL,
  "discount_amount" numeric(10,2) DEFAULT 0.0,
  "subtotal" numeric(10,2) NOT NULL,
  "product_snapshot" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT check_item_amounts_positive CHECK (((unit_price > (0)::numeric) AND (discount_amount >= (0)::numeric) AND (subtotal >= (0)::numeric)))
);

CREATE TABLE IF NOT EXISTS orders (
  "id" bigint NOT NULL DEFAULT nextval('orders_id_seq'::regclass),
  "user_id" bigint NOT NULL,
  "order_number" varchar NOT NULL,
  "status" post_status NOT NULL DEFAULT 'draft'::post_status,
  "subtotal" numeric(10,2) NOT NULL DEFAULT 0.0,
  "tax_amount" numeric(10,2) NOT NULL DEFAULT 0.0,
  "shipping_cost" numeric(10,2) NOT NULL DEFAULT 0.0,
  "total_amount" numeric(10,2) NOT NULL DEFAULT 0.0,
  "shipping_address" jsonb DEFAULT '{}'::jsonb,
  "billing_address" jsonb DEFAULT '{}'::jsonb,
  "notes" text,
  "confirmed_at" timestamp,
  "shipped_at" timestamp,
  "delivered_at" timestamp,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT check_order_amounts_positive CHECK (((subtotal >= (0)::numeric) AND (tax_amount >= (0)::numeric) AND (shipping_cost >= (0)::numeric) AND (total_amount >= (0)::numeric)))
);

CREATE TABLE IF NOT EXISTS posts (
  "id" bigint NOT NULL DEFAULT nextval('posts_id_seq'::regclass),
  "user_id" bigint NOT NULL,
  "title" varchar NOT NULL,
  "body" text,
  "published_at" timestamp,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS product_price_history (
  "id" bigint NOT NULL DEFAULT nextval('product_price_history_id_seq'::regclass),
  "product_id" bigint NOT NULL,
  "old_price" numeric(10,2),
  "new_price" numeric(10,2) NOT NULL,
  "changed_at" timestamp NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS products (
  "id" bigint NOT NULL DEFAULT nextval('products_id_seq'::regclass),
  "category_id" bigint NOT NULL,
  "name" varchar NOT NULL,
  "sku" varchar NOT NULL,
  "description" text,
  "price" numeric(10,2) NOT NULL,
  "discount_percentage" numeric(5,2),
  "stock_quantity" integer NOT NULL DEFAULT 0,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "specifications" jsonb DEFAULT '{}'::jsonb,
  "tags" varchar[] DEFAULT '{}'::character varying[],
  "is_active" boolean DEFAULT true,
  "is_featured" boolean DEFAULT false,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT check_discount_range CHECK (((discount_percentage >= (0)::numeric) AND (discount_percentage <= (100)::numeric))),
  CONSTRAINT check_price_positive CHECK ((price > (0)::numeric)),
  CONSTRAINT check_stock_non_negative CHECK ((stock_quantity >= 0))
);

CREATE TABLE IF NOT EXISTS schema_migrations (
  "version" varchar NOT NULL,
  PRIMARY KEY ("version")
);

CREATE TABLE IF NOT EXISTS sessions (
  "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
  "user_id" bigint NOT NULL,
  "token" varchar NOT NULL,
  "ip_address" inet,
  "user_agent" varchar,
  "expires_at" timestamp NOT NULL,
  "last_accessed_at" timestamp,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS users (
  "id" bigint NOT NULL DEFAULT nextval('users_id_seq'::regclass),
  "email" varchar NOT NULL,
  "encrypted_password" varchar,
  "uuid" uuid DEFAULT uuid_generate_v4(),
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
