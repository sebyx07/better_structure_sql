CREATE TABLE IF NOT EXISTS ar_internal_metadata (
  "key" varchar NOT NULL,
  "value" varchar,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("key")
);

CREATE TABLE IF NOT EXISTS better_structure_sql_schema_versions (
  "id" bigint NOT NULL DEFAULT nextval('better_structure_sql_schema_versions_id_seq'::regclass),
  "content" text NOT NULL,
  "zip_archive" bytea,
  "pg_version" varchar NOT NULL,
  "format_type" varchar NOT NULL,
  "output_mode" varchar NOT NULL,
  "content_size" bigint NOT NULL,
  "line_count" integer NOT NULL,
  "file_count" integer,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  "content_hash" varchar(32) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT format_type_check CHECK (((format_type)::text = ANY ((ARRAY['sql'::character varying, 'rb'::character varying])::text[]))),
  CONSTRAINT output_mode_check CHECK (((output_mode)::text = ANY ((ARRAY['single_file'::character varying, 'multi_file'::character varying])::text[])))
);

CREATE TABLE IF NOT EXISTS categories (
  "id" bigint NOT NULL DEFAULT nextval('categories_id_seq'::regclass),
  "name" varchar NOT NULL,
  "slug" varchar NOT NULL,
  "description" text,
  "parent_id" integer,
  "position" integer DEFAULT 0,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS events (
  "id" uuid NOT NULL DEFAULT uuid_generate_v8(),
  "user_id" bigint,
  "event_type" varchar NOT NULL,
  "event_name" varchar NOT NULL,
  "event_data" jsonb DEFAULT '{}'::jsonb,
  "ip_address" inet,
  "user_agent" varchar,
  "occurred_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("id"),
  CONSTRAINT check_event_type_not_empty CHECK (((length((event_type)::text) > 0) AND (length((event_name)::text) > 0)))
);

CREATE TABLE IF NOT EXISTS large_table_000 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_000_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_000_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_001 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_001_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_001_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_002 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_002_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_002_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_003 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_003_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_003_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_004 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_004_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_004_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_005 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_005_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_005_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_006 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_006_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_006_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_007 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_007_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_007_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_008 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_008_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_008_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_009 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_009_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_009_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_010 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_010_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_010_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_011 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_011_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_011_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_012 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_012_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_012_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_013 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_013_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_013_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_014 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_014_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_014_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_015 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_015_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_015_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_016 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_016_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_016_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_017 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_017_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_017_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_018 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_018_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_018_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_019 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_019_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_019_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_020 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_020_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_020_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_021 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_021_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_021_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_022 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_022_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_022_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_023 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_023_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_023_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_024 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_024_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_024_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_025 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_025_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_025_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_026 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_026_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_026_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_027 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_027_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_027_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_028 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_028_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_028_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE IF NOT EXISTS large_table_029 (
  "id" bigint NOT NULL DEFAULT nextval('large_table_029_id_seq'::regclass),
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
  CONSTRAINT chk_large_table_029_status CHECK (((status >= 0) AND (status <= 10)))
);
