SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

-- Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

SET search_path TO public;

-- Custom Types
CREATE TYPE address AS (street character varying(255), city character varying(100), state character varying(2), zip_code character varying(10), country character varying(50));
CREATE TYPE post_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE priority_level AS ENUM ('low', 'medium', 'high', 'urgent');
CREATE TYPE user_role AS ENUM ('admin', 'moderator', 'user', 'guest');

-- Domains
CREATE DOMAIN email_address AS character varying(255) CHECK (((VALUE)::text ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Z|a-z]{2,}$'::text));
CREATE DOMAIN percentage AS numeric(5,2) CHECK (((VALUE >= (0)::numeric) AND (VALUE <= (100)::numeric)));
CREATE DOMAIN positive_integer AS integer CHECK ((VALUE > 0));

-- Functions

CREATE OR REPLACE FUNCTION public.audit_product_price_change()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF OLD.price IS DISTINCT FROM NEW.price THEN
    INSERT INTO product_price_history (product_id, old_price, new_price, changed_at)
    VALUES (NEW.id, OLD.price, NEW.price, CURRENT_TIMESTAMP);
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_discount_price(original_price numeric, discount_percent numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  IF discount_percent IS NULL OR discount_percent = 0 THEN
    RETURN original_price;
  END IF;
  RETURN ROUND(original_price * (1 - discount_percent / 100), 2);
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_0(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.0 + 0;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_1(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.1 + 10;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_2(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.2 + 20;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_3(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.3 + 30;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_4(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.4 + 40;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_5(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.5 + 50;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_6(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.6 + 60;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_7(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.7 + 70;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_8(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.8 + 80;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_9(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.9 + 90;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_0()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_1()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_10()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_11()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_12()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_13()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_14()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_2()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_3()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_4()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_5()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_6()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_7()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_8()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_9()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.uuid_generate_v8()
 RETURNS uuid
 LANGUAGE plpgsql
AS $function$
DECLARE
  timestamp timestamptz;
  microseconds int;
BEGIN
  timestamp := clock_timestamp();
  microseconds := (cast(extract(microseconds from timestamp)::int -
    (floor(extract(milliseconds from timestamp))::int * 1000) as double precision) * 4.096)::int;

  RETURN encode(
    set_byte(
      set_byte(
        overlay(uuid_send(gen_random_uuid())
          placing substring(int8send(floor(extract(epoch from timestamp) * 1000)::bigint) from 3)
          from 1 for 6
        ),
        6, (b'1000' || (microseconds >> 8)::bit(4))::bit(8)::int
      ),
      7, microseconds::bit(8)::int
    ),
    'hex')::uuid;
END
$function$;

CREATE OR REPLACE FUNCTION public.validate_email(email_text text)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  RETURN email_text ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Z|a-z]{2,}$';
END;
$function$;

-- Sequences
CREATE SEQUENCE better_structure_sql_schema_versions_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE categories_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_000_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_001_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_002_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_003_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_004_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_005_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_006_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_007_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_008_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_009_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_010_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_011_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_012_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_013_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_014_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_015_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_016_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_017_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_018_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_019_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_020_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_021_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_022_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_023_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_024_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_025_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_026_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_027_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_028_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_029_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_030_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_031_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_032_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_033_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_034_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_035_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_036_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_037_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_038_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_039_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_040_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_041_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_042_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_043_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_044_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_045_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_046_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_047_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_048_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE large_table_049_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE order_items_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE orders_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE posts_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE product_price_history_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE products_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE users_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;

SET default_tablespace = '';

SET default_table_access_method = heap;

-- Tables

CREATE TABLE ar_internal_metadata (
  key varchar NOT NULL,
  value varchar,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (key)
);

CREATE TABLE better_structure_sql_schema_versions (
  id bigint NOT NULL DEFAULT nextval('better_structure_sql_schema_versions_id_seq'::regclass),
  content text NOT NULL,
  zip_archive bytea,
  pg_version varchar NOT NULL,
  format_type varchar NOT NULL,
  output_mode varchar NOT NULL,
  content_size bigint NOT NULL,
  line_count integer NOT NULL,
  file_count integer,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT format_type_check CHECK (((format_type)::text = ANY (ARRAY[('sql'::character varying)::text, ('rb'::character varying)::text]))),
  CONSTRAINT output_mode_check CHECK (((output_mode)::text = ANY (ARRAY[('single_file'::character varying)::text, ('multi_file'::character varying)::text])))
);

CREATE TABLE categories (
  id bigint NOT NULL DEFAULT nextval('categories_id_seq'::regclass),
  name varchar NOT NULL,
  slug varchar NOT NULL,
  description text,
  parent_id integer,
  position integer DEFAULT 0,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE events (
  id uuid NOT NULL DEFAULT uuid_generate_v8(),
  user_id bigint,
  event_type varchar NOT NULL,
  event_name varchar NOT NULL,
  event_data jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  user_agent varchar,
  occurred_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT check_event_type_not_empty CHECK (((length((event_type)::text) > 0) AND (length((event_name)::text) > 0)))
);

CREATE TABLE large_table_000 (
  id bigint NOT NULL DEFAULT nextval('large_table_000_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_000_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_001 (
  id bigint NOT NULL DEFAULT nextval('large_table_001_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_001_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_002 (
  id bigint NOT NULL DEFAULT nextval('large_table_002_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_002_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_003 (
  id bigint NOT NULL DEFAULT nextval('large_table_003_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_003_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_004 (
  id bigint NOT NULL DEFAULT nextval('large_table_004_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_004_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_005 (
  id bigint NOT NULL DEFAULT nextval('large_table_005_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_005_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_006 (
  id bigint NOT NULL DEFAULT nextval('large_table_006_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_006_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_007 (
  id bigint NOT NULL DEFAULT nextval('large_table_007_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_007_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_008 (
  id bigint NOT NULL DEFAULT nextval('large_table_008_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_008_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_009 (
  id bigint NOT NULL DEFAULT nextval('large_table_009_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_009_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_010 (
  id bigint NOT NULL DEFAULT nextval('large_table_010_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_010_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_011 (
  id bigint NOT NULL DEFAULT nextval('large_table_011_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_011_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_012 (
  id bigint NOT NULL DEFAULT nextval('large_table_012_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_012_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_013 (
  id bigint NOT NULL DEFAULT nextval('large_table_013_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_013_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_014 (
  id bigint NOT NULL DEFAULT nextval('large_table_014_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_014_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_015 (
  id bigint NOT NULL DEFAULT nextval('large_table_015_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_015_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_016 (
  id bigint NOT NULL DEFAULT nextval('large_table_016_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_016_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_017 (
  id bigint NOT NULL DEFAULT nextval('large_table_017_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_017_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_018 (
  id bigint NOT NULL DEFAULT nextval('large_table_018_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_018_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_019 (
  id bigint NOT NULL DEFAULT nextval('large_table_019_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_019_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_020 (
  id bigint NOT NULL DEFAULT nextval('large_table_020_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_020_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_021 (
  id bigint NOT NULL DEFAULT nextval('large_table_021_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_021_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_022 (
  id bigint NOT NULL DEFAULT nextval('large_table_022_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_022_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_023 (
  id bigint NOT NULL DEFAULT nextval('large_table_023_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_023_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_024 (
  id bigint NOT NULL DEFAULT nextval('large_table_024_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_024_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_025 (
  id bigint NOT NULL DEFAULT nextval('large_table_025_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_025_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_026 (
  id bigint NOT NULL DEFAULT nextval('large_table_026_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_026_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_027 (
  id bigint NOT NULL DEFAULT nextval('large_table_027_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_027_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_028 (
  id bigint NOT NULL DEFAULT nextval('large_table_028_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_028_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_029 (
  id bigint NOT NULL DEFAULT nextval('large_table_029_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_029_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_030 (
  id bigint NOT NULL DEFAULT nextval('large_table_030_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_030_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_031 (
  id bigint NOT NULL DEFAULT nextval('large_table_031_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_031_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_032 (
  id bigint NOT NULL DEFAULT nextval('large_table_032_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_032_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_033 (
  id bigint NOT NULL DEFAULT nextval('large_table_033_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_033_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_034 (
  id bigint NOT NULL DEFAULT nextval('large_table_034_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_034_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_035 (
  id bigint NOT NULL DEFAULT nextval('large_table_035_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_035_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_036 (
  id bigint NOT NULL DEFAULT nextval('large_table_036_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_036_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_037 (
  id bigint NOT NULL DEFAULT nextval('large_table_037_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_037_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_038 (
  id bigint NOT NULL DEFAULT nextval('large_table_038_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_038_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_039 (
  id bigint NOT NULL DEFAULT nextval('large_table_039_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_039_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_040 (
  id bigint NOT NULL DEFAULT nextval('large_table_040_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_040_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_041 (
  id bigint NOT NULL DEFAULT nextval('large_table_041_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_041_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_042 (
  id bigint NOT NULL DEFAULT nextval('large_table_042_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_042_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_043 (
  id bigint NOT NULL DEFAULT nextval('large_table_043_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_043_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_044 (
  id bigint NOT NULL DEFAULT nextval('large_table_044_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_044_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_045 (
  id bigint NOT NULL DEFAULT nextval('large_table_045_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_045_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_046 (
  id bigint NOT NULL DEFAULT nextval('large_table_046_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_046_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_047 (
  id bigint NOT NULL DEFAULT nextval('large_table_047_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_047_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_048 (
  id bigint NOT NULL DEFAULT nextval('large_table_048_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  related_id bigint,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_048_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE large_table_049 (
  id bigint NOT NULL DEFAULT nextval('large_table_049_id_seq'::regclass),
  name varchar NOT NULL,
  description text,
  status integer DEFAULT 0,
  price numeric(10,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  external_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_large_table_049_status CHECK (((status >= 0) AND (status <= 10)))
);

CREATE TABLE order_items (
  id bigint NOT NULL DEFAULT nextval('order_items_id_seq'::regclass),
  order_id bigint NOT NULL,
  product_id bigint NOT NULL,
  quantity integer NOT NULL,
  unit_price numeric(10,2) NOT NULL,
  discount_amount numeric(10,2) DEFAULT 0.0,
  subtotal numeric(10,2) NOT NULL,
  product_snapshot jsonb DEFAULT '{}'::jsonb,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT check_item_amounts_positive CHECK (((unit_price > (0)::numeric) AND (discount_amount >= (0)::numeric) AND (subtotal >= (0)::numeric)))
);

CREATE TABLE orders (
  id bigint NOT NULL DEFAULT nextval('orders_id_seq'::regclass),
  user_id bigint NOT NULL,
  order_number varchar NOT NULL,
  status post_status NOT NULL DEFAULT 'draft'::post_status,
  subtotal numeric(10,2) NOT NULL DEFAULT 0.0,
  tax_amount numeric(10,2) NOT NULL DEFAULT 0.0,
  shipping_cost numeric(10,2) NOT NULL DEFAULT 0.0,
  total_amount numeric(10,2) NOT NULL DEFAULT 0.0,
  shipping_address jsonb DEFAULT '{}'::jsonb,
  billing_address jsonb DEFAULT '{}'::jsonb,
  notes text,
  confirmed_at timestamp,
  shipped_at timestamp,
  delivered_at timestamp,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT check_order_amounts_positive CHECK (((subtotal >= (0)::numeric) AND (tax_amount >= (0)::numeric) AND (shipping_cost >= (0)::numeric) AND (total_amount >= (0)::numeric)))
);

CREATE TABLE posts (
  id bigint NOT NULL DEFAULT nextval('posts_id_seq'::regclass),
  user_id bigint NOT NULL,
  title varchar NOT NULL,
  body text,
  published_at timestamp,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE product_price_history (
  id bigint NOT NULL DEFAULT nextval('product_price_history_id_seq'::regclass),
  product_id bigint NOT NULL,
  old_price numeric(10,2),
  new_price numeric(10,2) NOT NULL,
  changed_at timestamp NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE products (
  id bigint NOT NULL DEFAULT nextval('products_id_seq'::regclass),
  category_id bigint NOT NULL,
  name varchar NOT NULL,
  sku varchar NOT NULL,
  description text,
  price numeric(10,2) NOT NULL,
  discount_percentage numeric(5,2),
  stock_quantity integer NOT NULL DEFAULT 0,
  metadata jsonb DEFAULT '{}'::jsonb,
  specifications jsonb DEFAULT '{}'::jsonb,
  tags varchar[] DEFAULT '{}'::character varying[],
  is_active boolean DEFAULT true,
  is_featured boolean DEFAULT false,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT check_discount_range CHECK (((discount_percentage >= (0)::numeric) AND (discount_percentage <= (100)::numeric))),
  CONSTRAINT check_price_positive CHECK ((price > (0)::numeric)),
  CONSTRAINT check_stock_non_negative CHECK ((stock_quantity >= 0))
);

CREATE TABLE schema_migrations (
  version varchar NOT NULL,
  PRIMARY KEY (version)
);

CREATE TABLE sessions (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id bigint NOT NULL,
  token varchar NOT NULL,
  ip_address inet,
  user_agent varchar,
  expires_at timestamp NOT NULL,
  last_accessed_at timestamp,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE users (
  id bigint NOT NULL DEFAULT nextval('users_id_seq'::regclass),
  email varchar NOT NULL,
  encrypted_password varchar,
  uuid uuid DEFAULT uuid_generate_v4(),
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id)
);

-- Indexes
CREATE INDEX index_better_structure_sql_schema_versions_on_created_at ON public.better_structure_sql_schema_versions USING btree (created_at DESC);
CREATE INDEX index_better_structure_sql_schema_versions_on_output_mode ON public.better_structure_sql_schema_versions USING btree (output_mode);
CREATE INDEX index_categories_on_lower_name ON public.categories USING btree (lower((name)::text));
CREATE INDEX index_categories_on_parent_id ON public.categories USING btree (parent_id);
CREATE INDEX index_categories_on_position ON public.categories USING btree ("position");
CREATE UNIQUE INDEX index_categories_on_slug ON public.categories USING btree (slug);
CREATE INDEX index_events_on_event_data ON public.events USING gin (event_data);
CREATE INDEX index_events_on_event_name ON public.events USING btree (event_name);
CREATE INDEX index_events_on_event_type ON public.events USING btree (event_type);
CREATE INDEX index_events_on_occurred_at ON public.events USING brin (occurred_at);
CREATE INDEX index_events_on_user_id ON public.events USING btree (user_id);
CREATE INDEX index_events_on_user_id_and_occurred_at ON public.events USING btree (user_id, occurred_at);
CREATE INDEX idx_large_table_000_active_status ON public.large_table_000 USING btree (active, status);
CREATE INDEX index_large_table_000_on_name ON public.large_table_000 USING btree (name);
CREATE INDEX index_large_table_000_on_status ON public.large_table_000 USING btree (status);
CREATE INDEX idx_large_table_001_active_status ON public.large_table_001 USING btree (active, status);
CREATE INDEX index_large_table_001_on_name ON public.large_table_001 USING btree (name);
CREATE INDEX index_large_table_001_on_status ON public.large_table_001 USING btree (status);
CREATE INDEX idx_large_table_002_active_status ON public.large_table_002 USING btree (active, status);
CREATE INDEX index_large_table_002_on_name ON public.large_table_002 USING btree (name);
CREATE INDEX index_large_table_002_on_status ON public.large_table_002 USING btree (status);
CREATE INDEX idx_large_table_003_active_status ON public.large_table_003 USING btree (active, status);
CREATE INDEX index_large_table_003_on_name ON public.large_table_003 USING btree (name);
CREATE INDEX index_large_table_003_on_status ON public.large_table_003 USING btree (status);
CREATE INDEX idx_large_table_004_active_status ON public.large_table_004 USING btree (active, status);
CREATE INDEX index_large_table_004_on_name ON public.large_table_004 USING btree (name);
CREATE INDEX index_large_table_004_on_status ON public.large_table_004 USING btree (status);
CREATE INDEX idx_large_table_005_active_status ON public.large_table_005 USING btree (active, status);
CREATE INDEX index_large_table_005_on_name ON public.large_table_005 USING btree (name);
CREATE INDEX index_large_table_005_on_status ON public.large_table_005 USING btree (status);
CREATE INDEX idx_large_table_006_active_status ON public.large_table_006 USING btree (active, status);
CREATE INDEX index_large_table_006_on_name ON public.large_table_006 USING btree (name);
CREATE INDEX index_large_table_006_on_status ON public.large_table_006 USING btree (status);
CREATE INDEX idx_large_table_007_active_status ON public.large_table_007 USING btree (active, status);
CREATE INDEX index_large_table_007_on_name ON public.large_table_007 USING btree (name);
CREATE INDEX index_large_table_007_on_status ON public.large_table_007 USING btree (status);
CREATE INDEX idx_large_table_008_active_status ON public.large_table_008 USING btree (active, status);
CREATE INDEX index_large_table_008_on_name ON public.large_table_008 USING btree (name);
CREATE INDEX index_large_table_008_on_status ON public.large_table_008 USING btree (status);
CREATE INDEX idx_large_table_009_active_status ON public.large_table_009 USING btree (active, status);
CREATE INDEX index_large_table_009_on_name ON public.large_table_009 USING btree (name);
CREATE INDEX index_large_table_009_on_status ON public.large_table_009 USING btree (status);
CREATE INDEX idx_large_table_010_active_status ON public.large_table_010 USING btree (active, status);
CREATE INDEX index_large_table_010_on_name ON public.large_table_010 USING btree (name);
CREATE INDEX index_large_table_010_on_status ON public.large_table_010 USING btree (status);
CREATE INDEX idx_large_table_011_active_status ON public.large_table_011 USING btree (active, status);
CREATE INDEX index_large_table_011_on_name ON public.large_table_011 USING btree (name);
CREATE INDEX index_large_table_011_on_status ON public.large_table_011 USING btree (status);
CREATE INDEX idx_large_table_012_active_status ON public.large_table_012 USING btree (active, status);
CREATE INDEX index_large_table_012_on_name ON public.large_table_012 USING btree (name);
CREATE INDEX index_large_table_012_on_status ON public.large_table_012 USING btree (status);
CREATE INDEX idx_large_table_013_active_status ON public.large_table_013 USING btree (active, status);
CREATE INDEX index_large_table_013_on_name ON public.large_table_013 USING btree (name);
CREATE INDEX index_large_table_013_on_status ON public.large_table_013 USING btree (status);
CREATE INDEX idx_large_table_014_active_status ON public.large_table_014 USING btree (active, status);
CREATE INDEX index_large_table_014_on_name ON public.large_table_014 USING btree (name);
CREATE INDEX index_large_table_014_on_status ON public.large_table_014 USING btree (status);
CREATE INDEX idx_large_table_015_active_status ON public.large_table_015 USING btree (active, status);
CREATE INDEX index_large_table_015_on_name ON public.large_table_015 USING btree (name);
CREATE INDEX index_large_table_015_on_status ON public.large_table_015 USING btree (status);
CREATE INDEX idx_large_table_016_active_status ON public.large_table_016 USING btree (active, status);
CREATE INDEX index_large_table_016_on_name ON public.large_table_016 USING btree (name);
CREATE INDEX index_large_table_016_on_status ON public.large_table_016 USING btree (status);
CREATE INDEX idx_large_table_017_active_status ON public.large_table_017 USING btree (active, status);
CREATE INDEX index_large_table_017_on_name ON public.large_table_017 USING btree (name);
CREATE INDEX index_large_table_017_on_status ON public.large_table_017 USING btree (status);
CREATE INDEX idx_large_table_018_active_status ON public.large_table_018 USING btree (active, status);
CREATE INDEX index_large_table_018_on_name ON public.large_table_018 USING btree (name);
CREATE INDEX index_large_table_018_on_status ON public.large_table_018 USING btree (status);
CREATE INDEX idx_large_table_019_active_status ON public.large_table_019 USING btree (active, status);
CREATE INDEX index_large_table_019_on_name ON public.large_table_019 USING btree (name);
CREATE INDEX index_large_table_019_on_status ON public.large_table_019 USING btree (status);
CREATE INDEX idx_large_table_020_active_status ON public.large_table_020 USING btree (active, status);
CREATE INDEX index_large_table_020_on_name ON public.large_table_020 USING btree (name);
CREATE INDEX index_large_table_020_on_status ON public.large_table_020 USING btree (status);
CREATE INDEX idx_large_table_021_active_status ON public.large_table_021 USING btree (active, status);
CREATE INDEX index_large_table_021_on_name ON public.large_table_021 USING btree (name);
CREATE INDEX index_large_table_021_on_status ON public.large_table_021 USING btree (status);
CREATE INDEX idx_large_table_022_active_status ON public.large_table_022 USING btree (active, status);
CREATE INDEX index_large_table_022_on_name ON public.large_table_022 USING btree (name);
CREATE INDEX index_large_table_022_on_status ON public.large_table_022 USING btree (status);
CREATE INDEX idx_large_table_023_active_status ON public.large_table_023 USING btree (active, status);
CREATE INDEX index_large_table_023_on_name ON public.large_table_023 USING btree (name);
CREATE INDEX index_large_table_023_on_status ON public.large_table_023 USING btree (status);
CREATE INDEX idx_large_table_024_active_status ON public.large_table_024 USING btree (active, status);
CREATE INDEX index_large_table_024_on_name ON public.large_table_024 USING btree (name);
CREATE INDEX index_large_table_024_on_status ON public.large_table_024 USING btree (status);
CREATE INDEX idx_large_table_025_active_status ON public.large_table_025 USING btree (active, status);
CREATE INDEX index_large_table_025_on_name ON public.large_table_025 USING btree (name);
CREATE INDEX index_large_table_025_on_status ON public.large_table_025 USING btree (status);
CREATE INDEX idx_large_table_026_active_status ON public.large_table_026 USING btree (active, status);
CREATE INDEX index_large_table_026_on_name ON public.large_table_026 USING btree (name);
CREATE INDEX index_large_table_026_on_status ON public.large_table_026 USING btree (status);
CREATE INDEX idx_large_table_027_active_status ON public.large_table_027 USING btree (active, status);
CREATE INDEX index_large_table_027_on_name ON public.large_table_027 USING btree (name);
CREATE INDEX index_large_table_027_on_status ON public.large_table_027 USING btree (status);
CREATE INDEX idx_large_table_028_active_status ON public.large_table_028 USING btree (active, status);
CREATE INDEX index_large_table_028_on_name ON public.large_table_028 USING btree (name);
CREATE INDEX index_large_table_028_on_status ON public.large_table_028 USING btree (status);
CREATE INDEX idx_large_table_029_active_status ON public.large_table_029 USING btree (active, status);
CREATE INDEX index_large_table_029_on_name ON public.large_table_029 USING btree (name);
CREATE INDEX index_large_table_029_on_status ON public.large_table_029 USING btree (status);
CREATE INDEX idx_large_table_030_active_status ON public.large_table_030 USING btree (active, status);
CREATE INDEX index_large_table_030_on_name ON public.large_table_030 USING btree (name);
CREATE INDEX index_large_table_030_on_status ON public.large_table_030 USING btree (status);
CREATE INDEX idx_large_table_031_active_status ON public.large_table_031 USING btree (active, status);
CREATE INDEX index_large_table_031_on_name ON public.large_table_031 USING btree (name);
CREATE INDEX index_large_table_031_on_status ON public.large_table_031 USING btree (status);
CREATE INDEX idx_large_table_032_active_status ON public.large_table_032 USING btree (active, status);
CREATE INDEX index_large_table_032_on_name ON public.large_table_032 USING btree (name);
CREATE INDEX index_large_table_032_on_status ON public.large_table_032 USING btree (status);
CREATE INDEX idx_large_table_033_active_status ON public.large_table_033 USING btree (active, status);
CREATE INDEX index_large_table_033_on_name ON public.large_table_033 USING btree (name);
CREATE INDEX index_large_table_033_on_status ON public.large_table_033 USING btree (status);
CREATE INDEX idx_large_table_034_active_status ON public.large_table_034 USING btree (active, status);
CREATE INDEX index_large_table_034_on_name ON public.large_table_034 USING btree (name);
CREATE INDEX index_large_table_034_on_status ON public.large_table_034 USING btree (status);
CREATE INDEX idx_large_table_035_active_status ON public.large_table_035 USING btree (active, status);
CREATE INDEX index_large_table_035_on_name ON public.large_table_035 USING btree (name);
CREATE INDEX index_large_table_035_on_status ON public.large_table_035 USING btree (status);
CREATE INDEX idx_large_table_036_active_status ON public.large_table_036 USING btree (active, status);
CREATE INDEX index_large_table_036_on_name ON public.large_table_036 USING btree (name);
CREATE INDEX index_large_table_036_on_status ON public.large_table_036 USING btree (status);
CREATE INDEX idx_large_table_037_active_status ON public.large_table_037 USING btree (active, status);
CREATE INDEX index_large_table_037_on_name ON public.large_table_037 USING btree (name);
CREATE INDEX index_large_table_037_on_status ON public.large_table_037 USING btree (status);
CREATE INDEX idx_large_table_038_active_status ON public.large_table_038 USING btree (active, status);
CREATE INDEX index_large_table_038_on_name ON public.large_table_038 USING btree (name);
CREATE INDEX index_large_table_038_on_status ON public.large_table_038 USING btree (status);
CREATE INDEX idx_large_table_039_active_status ON public.large_table_039 USING btree (active, status);
CREATE INDEX index_large_table_039_on_name ON public.large_table_039 USING btree (name);
CREATE INDEX index_large_table_039_on_status ON public.large_table_039 USING btree (status);
CREATE INDEX idx_large_table_040_active_status ON public.large_table_040 USING btree (active, status);
CREATE INDEX index_large_table_040_on_name ON public.large_table_040 USING btree (name);
CREATE INDEX index_large_table_040_on_status ON public.large_table_040 USING btree (status);
CREATE INDEX idx_large_table_041_active_status ON public.large_table_041 USING btree (active, status);
CREATE INDEX index_large_table_041_on_name ON public.large_table_041 USING btree (name);
CREATE INDEX index_large_table_041_on_status ON public.large_table_041 USING btree (status);
CREATE INDEX idx_large_table_042_active_status ON public.large_table_042 USING btree (active, status);
CREATE INDEX index_large_table_042_on_name ON public.large_table_042 USING btree (name);
CREATE INDEX index_large_table_042_on_status ON public.large_table_042 USING btree (status);
CREATE INDEX idx_large_table_043_active_status ON public.large_table_043 USING btree (active, status);
CREATE INDEX index_large_table_043_on_name ON public.large_table_043 USING btree (name);
CREATE INDEX index_large_table_043_on_status ON public.large_table_043 USING btree (status);
CREATE INDEX idx_large_table_044_active_status ON public.large_table_044 USING btree (active, status);
CREATE INDEX index_large_table_044_on_name ON public.large_table_044 USING btree (name);
CREATE INDEX index_large_table_044_on_status ON public.large_table_044 USING btree (status);
CREATE INDEX idx_large_table_045_active_status ON public.large_table_045 USING btree (active, status);
CREATE INDEX index_large_table_045_on_name ON public.large_table_045 USING btree (name);
CREATE INDEX index_large_table_045_on_status ON public.large_table_045 USING btree (status);
CREATE INDEX idx_large_table_046_active_status ON public.large_table_046 USING btree (active, status);
CREATE INDEX index_large_table_046_on_name ON public.large_table_046 USING btree (name);
CREATE INDEX index_large_table_046_on_status ON public.large_table_046 USING btree (status);
CREATE INDEX idx_large_table_047_active_status ON public.large_table_047 USING btree (active, status);
CREATE INDEX index_large_table_047_on_name ON public.large_table_047 USING btree (name);
CREATE INDEX index_large_table_047_on_status ON public.large_table_047 USING btree (status);
CREATE INDEX idx_large_table_048_active_status ON public.large_table_048 USING btree (active, status);
CREATE INDEX index_large_table_048_on_name ON public.large_table_048 USING btree (name);
CREATE INDEX index_large_table_048_on_status ON public.large_table_048 USING btree (status);
CREATE INDEX idx_large_table_049_active_status ON public.large_table_049 USING btree (active, status);
CREATE INDEX index_large_table_049_on_name ON public.large_table_049 USING btree (name);
CREATE INDEX index_large_table_049_on_status ON public.large_table_049 USING btree (status);
CREATE INDEX index_order_items_on_order_id ON public.order_items USING btree (order_id);
CREATE UNIQUE INDEX index_order_items_on_order_id_and_product_id ON public.order_items USING btree (order_id, product_id);
CREATE INDEX index_order_items_on_product_id ON public.order_items USING btree (product_id);
CREATE INDEX index_orders_created_at_brin ON public.orders USING brin (created_at);
CREATE INDEX index_orders_on_confirmed_at ON public.orders USING btree (confirmed_at) WHERE (confirmed_at IS NOT NULL);
CREATE INDEX index_orders_on_created_at ON public.orders USING btree (created_at);
CREATE UNIQUE INDEX index_orders_on_order_number ON public.orders USING btree (order_number);
CREATE INDEX index_orders_on_shipped_at ON public.orders USING btree (shipped_at) WHERE (shipped_at IS NOT NULL);
CREATE INDEX index_orders_on_status ON public.orders USING btree (status);
CREATE INDEX index_orders_on_user_id ON public.orders USING btree (user_id);
CREATE INDEX index_orders_shipping_address_path ON public.orders USING gin (shipping_address jsonb_path_ops);
CREATE INDEX index_posts_on_published_at ON public.posts USING btree (published_at) WHERE (published_at IS NOT NULL);
CREATE INDEX index_posts_on_user_id ON public.posts USING btree (user_id);
CREATE INDEX index_product_price_history_on_product_id ON public.product_price_history USING btree (product_id);
CREATE INDEX index_product_price_history_on_product_id_and_changed_at ON public.product_price_history USING btree (product_id, changed_at);
CREATE UNIQUE INDEX index_active_products_unique_sku ON public.products USING btree (sku) WHERE (is_active = true);
CREATE INDEX index_products_fulltext_search ON public.products USING gin (to_tsvector('english'::regconfig, (((COALESCE(name, ''::character varying))::text || ' '::text) || COALESCE(description, ''::text))));
CREATE INDEX index_products_metadata_path ON public.products USING gin (metadata jsonb_path_ops);
CREATE INDEX index_products_on_available_items ON public.products USING btree (category_id, is_active, price) WHERE ((is_active = true) AND (stock_quantity > 0));
CREATE INDEX index_products_on_category_id ON public.products USING btree (category_id);
CREATE INDEX index_products_on_category_id_and_price ON public.products USING btree (category_id, price);
CREATE INDEX index_products_on_created_at ON public.products USING btree (created_at);
CREATE INDEX index_products_on_discounted_price ON public.products USING btree (((price * ((1)::numeric - (COALESCE(discount_percentage, (0)::numeric) / (100)::numeric)))));
CREATE INDEX index_products_on_is_active ON public.products USING btree (is_active);
CREATE INDEX index_products_on_is_featured ON public.products USING btree (is_featured) WHERE (is_featured = true);
CREATE INDEX index_products_on_metadata ON public.products USING gin (metadata);
CREATE INDEX index_products_on_name ON public.products USING btree (name);
CREATE INDEX index_products_on_price ON public.products USING btree (price);
CREATE UNIQUE INDEX index_products_on_sku ON public.products USING btree (sku);
CREATE INDEX index_products_on_specifications ON public.products USING gin (specifications);
CREATE INDEX index_products_on_tags ON public.products USING gin (tags);
CREATE INDEX index_sessions_on_expires_at ON public.sessions USING btree (expires_at);
CREATE UNIQUE INDEX index_sessions_on_token ON public.sessions USING btree (token);
CREATE INDEX index_sessions_on_user_id ON public.sessions USING btree (user_id);
CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);
CREATE INDEX index_users_on_lower_email ON public.users USING btree (lower((email)::text));
CREATE INDEX index_users_on_uuid ON public.users USING btree (uuid);

-- Foreign Keys
ALTER TABLE categories ADD CONSTRAINT fk_rails_82f48f7407 FOREIGN KEY (parent_id) REFERENCES categories (id) ON DELETE CASCADE;
ALTER TABLE events ADD CONSTRAINT fk_rails_0cb5590091 FOREIGN KEY (user_id) REFERENCES users (id);
ALTER TABLE large_table_000 ADD CONSTRAINT fk_rails_4a0fe673f1 FOREIGN KEY (related_id) REFERENCES large_table_001 (id);
ALTER TABLE large_table_002 ADD CONSTRAINT fk_rails_10d4c7857f FOREIGN KEY (related_id) REFERENCES large_table_003 (id);
ALTER TABLE large_table_004 ADD CONSTRAINT fk_rails_403f789646 FOREIGN KEY (related_id) REFERENCES large_table_005 (id);
ALTER TABLE large_table_006 ADD CONSTRAINT fk_rails_0a2a5c7700 FOREIGN KEY (related_id) REFERENCES large_table_007 (id);
ALTER TABLE large_table_008 ADD CONSTRAINT fk_rails_2fe8a3e5c2 FOREIGN KEY (related_id) REFERENCES large_table_009 (id);
ALTER TABLE large_table_010 ADD CONSTRAINT fk_rails_8baf10fabf FOREIGN KEY (related_id) REFERENCES large_table_011 (id);
ALTER TABLE large_table_012 ADD CONSTRAINT fk_rails_8ff9e73b1c FOREIGN KEY (related_id) REFERENCES large_table_013 (id);
ALTER TABLE large_table_014 ADD CONSTRAINT fk_rails_c23a51d6d3 FOREIGN KEY (related_id) REFERENCES large_table_015 (id);
ALTER TABLE large_table_016 ADD CONSTRAINT fk_rails_6ff3f374a2 FOREIGN KEY (related_id) REFERENCES large_table_017 (id);
ALTER TABLE large_table_018 ADD CONSTRAINT fk_rails_95217f3d00 FOREIGN KEY (related_id) REFERENCES large_table_019 (id);
ALTER TABLE large_table_020 ADD CONSTRAINT fk_rails_4059e67133 FOREIGN KEY (related_id) REFERENCES large_table_021 (id);
ALTER TABLE large_table_022 ADD CONSTRAINT fk_rails_1750dd1c8c FOREIGN KEY (related_id) REFERENCES large_table_023 (id);
ALTER TABLE large_table_024 ADD CONSTRAINT fk_rails_64b98564cb FOREIGN KEY (related_id) REFERENCES large_table_025 (id);
ALTER TABLE large_table_026 ADD CONSTRAINT fk_rails_a24e0ff80a FOREIGN KEY (related_id) REFERENCES large_table_027 (id);
ALTER TABLE large_table_028 ADD CONSTRAINT fk_rails_37310c7788 FOREIGN KEY (related_id) REFERENCES large_table_029 (id);
ALTER TABLE large_table_030 ADD CONSTRAINT fk_rails_aa888a6236 FOREIGN KEY (related_id) REFERENCES large_table_031 (id);
ALTER TABLE large_table_032 ADD CONSTRAINT fk_rails_3b295accd5 FOREIGN KEY (related_id) REFERENCES large_table_033 (id);
ALTER TABLE large_table_034 ADD CONSTRAINT fk_rails_2b45e03f7f FOREIGN KEY (related_id) REFERENCES large_table_035 (id);
ALTER TABLE large_table_036 ADD CONSTRAINT fk_rails_17434a2d19 FOREIGN KEY (related_id) REFERENCES large_table_037 (id);
ALTER TABLE large_table_038 ADD CONSTRAINT fk_rails_4ce638a77b FOREIGN KEY (related_id) REFERENCES large_table_039 (id);
ALTER TABLE large_table_040 ADD CONSTRAINT fk_rails_cd44c375bc FOREIGN KEY (related_id) REFERENCES large_table_041 (id);
ALTER TABLE large_table_042 ADD CONSTRAINT fk_rails_061295adfe FOREIGN KEY (related_id) REFERENCES large_table_043 (id);
ALTER TABLE large_table_044 ADD CONSTRAINT fk_rails_1adeeaa1a6 FOREIGN KEY (related_id) REFERENCES large_table_045 (id);
ALTER TABLE large_table_046 ADD CONSTRAINT fk_rails_e606c0a7e9 FOREIGN KEY (related_id) REFERENCES large_table_047 (id);
ALTER TABLE large_table_048 ADD CONSTRAINT fk_rails_4e9b16baa9 FOREIGN KEY (related_id) REFERENCES large_table_049 (id);
ALTER TABLE order_items ADD CONSTRAINT fk_rails_e3cb28f071 FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE;
ALTER TABLE order_items ADD CONSTRAINT fk_rails_f1a29ddd47 FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT;
ALTER TABLE orders ADD CONSTRAINT fk_rails_f868b47f6a FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT;
ALTER TABLE posts ADD CONSTRAINT fk_rails_5b5ddfd518 FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE;
ALTER TABLE product_price_history ADD CONSTRAINT fk_rails_b70a9e116e FOREIGN KEY (product_id) REFERENCES products (id);
ALTER TABLE products ADD CONSTRAINT fk_rails_fb915499a4 FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT;
ALTER TABLE sessions ADD CONSTRAINT fk_rails_758836b4f0 FOREIGN KEY (user_id) REFERENCES users (id);

-- Views

CREATE VIEW active_products_view AS
SELECT p.id,
    p.name,
    p.sku,
    p.price,
    p.stock_quantity,
    c.name AS category_name,
    p.created_at
   FROM (products p
     JOIN categories c ON ((c.id = p.category_id)))
  WHERE (p.is_active = true)
  ORDER BY p.created_at DESC;

CREATE VIEW large_view_00 AS
SELECT large_table_000.id,
    large_table_000.name,
    large_table_000.status,
    large_table_000.active,
    large_table_000.created_at
   FROM large_table_000
  WHERE (large_table_000.active = true);

CREATE VIEW large_view_01 AS
SELECT large_table_002.id,
    large_table_002.name,
    large_table_002.status,
    large_table_002.active,
    large_table_002.created_at
   FROM large_table_002
  WHERE (large_table_002.active = true);

CREATE VIEW large_view_02 AS
SELECT large_table_004.id,
    large_table_004.name,
    large_table_004.status,
    large_table_004.active,
    large_table_004.created_at
   FROM large_table_004
  WHERE (large_table_004.active = true);

CREATE VIEW large_view_03 AS
SELECT large_table_006.id,
    large_table_006.name,
    large_table_006.status,
    large_table_006.active,
    large_table_006.created_at
   FROM large_table_006
  WHERE (large_table_006.active = true);

CREATE VIEW large_view_04 AS
SELECT large_table_008.id,
    large_table_008.name,
    large_table_008.status,
    large_table_008.active,
    large_table_008.created_at
   FROM large_table_008
  WHERE (large_table_008.active = true);

CREATE VIEW large_view_05 AS
SELECT large_table_010.id,
    large_table_010.name,
    large_table_010.status,
    large_table_010.active,
    large_table_010.created_at
   FROM large_table_010
  WHERE (large_table_010.active = true);

CREATE VIEW large_view_06 AS
SELECT large_table_012.id,
    large_table_012.name,
    large_table_012.status,
    large_table_012.active,
    large_table_012.created_at
   FROM large_table_012
  WHERE (large_table_012.active = true);

CREATE VIEW large_view_07 AS
SELECT large_table_014.id,
    large_table_014.name,
    large_table_014.status,
    large_table_014.active,
    large_table_014.created_at
   FROM large_table_014
  WHERE (large_table_014.active = true);

CREATE VIEW large_view_08 AS
SELECT large_table_016.id,
    large_table_016.name,
    large_table_016.status,
    large_table_016.active,
    large_table_016.created_at
   FROM large_table_016
  WHERE (large_table_016.active = true);

CREATE VIEW large_view_09 AS
SELECT large_table_018.id,
    large_table_018.name,
    large_table_018.status,
    large_table_018.active,
    large_table_018.created_at
   FROM large_table_018
  WHERE (large_table_018.active = true);

CREATE VIEW large_view_10 AS
SELECT large_table_020.id,
    large_table_020.name,
    large_table_020.status,
    large_table_020.active,
    large_table_020.created_at
   FROM large_table_020
  WHERE (large_table_020.active = true);

CREATE VIEW large_view_11 AS
SELECT large_table_022.id,
    large_table_022.name,
    large_table_022.status,
    large_table_022.active,
    large_table_022.created_at
   FROM large_table_022
  WHERE (large_table_022.active = true);

CREATE VIEW large_view_12 AS
SELECT large_table_024.id,
    large_table_024.name,
    large_table_024.status,
    large_table_024.active,
    large_table_024.created_at
   FROM large_table_024
  WHERE (large_table_024.active = true);

CREATE VIEW large_view_13 AS
SELECT large_table_026.id,
    large_table_026.name,
    large_table_026.status,
    large_table_026.active,
    large_table_026.created_at
   FROM large_table_026
  WHERE (large_table_026.active = true);

CREATE VIEW large_view_14 AS
SELECT large_table_028.id,
    large_table_028.name,
    large_table_028.status,
    large_table_028.active,
    large_table_028.created_at
   FROM large_table_028
  WHERE (large_table_028.active = true);

CREATE VIEW large_view_15 AS
SELECT large_table_030.id,
    large_table_030.name,
    large_table_030.status,
    large_table_030.active,
    large_table_030.created_at
   FROM large_table_030
  WHERE (large_table_030.active = true);

CREATE VIEW large_view_16 AS
SELECT large_table_032.id,
    large_table_032.name,
    large_table_032.status,
    large_table_032.active,
    large_table_032.created_at
   FROM large_table_032
  WHERE (large_table_032.active = true);

CREATE VIEW large_view_17 AS
SELECT large_table_034.id,
    large_table_034.name,
    large_table_034.status,
    large_table_034.active,
    large_table_034.created_at
   FROM large_table_034
  WHERE (large_table_034.active = true);

CREATE VIEW large_view_18 AS
SELECT large_table_036.id,
    large_table_036.name,
    large_table_036.status,
    large_table_036.active,
    large_table_036.created_at
   FROM large_table_036
  WHERE (large_table_036.active = true);

CREATE VIEW large_view_19 AS
SELECT large_table_038.id,
    large_table_038.name,
    large_table_038.status,
    large_table_038.active,
    large_table_038.created_at
   FROM large_table_038
  WHERE (large_table_038.active = true);

CREATE VIEW user_post_stats AS
SELECT u.id AS user_id,
    u.email,
    count(p.id) AS total_posts,
    count(p.id) FILTER (WHERE (p.published_at IS NOT NULL)) AS published_posts,
    max(p.published_at) AS last_published_at
   FROM (users u
     LEFT JOIN posts p ON ((p.user_id = u.id)))
  GROUP BY u.id, u.email;

-- Materialized Views

CREATE MATERIALIZED VIEW product_category_summary AS
SELECT c.id AS category_id,
    c.name AS category_name,
    count(p.id) AS product_count,
    avg(p.price) AS avg_price,
    min(p.price) AS min_price,
    max(p.price) AS max_price,
    sum(p.stock_quantity) AS total_stock
   FROM (categories c
     LEFT JOIN products p ON (((p.category_id = c.id) AND (p.is_active = true))))
  GROUP BY c.id, c.name;

CREATE INDEX index_product_category_summary_on_avg_price ON public.product_category_summary USING btree (avg_price);
CREATE UNIQUE INDEX index_product_category_summary_on_category_id ON public.product_category_summary USING btree (category_id);

-- Triggers

CREATE TRIGGER trigger_update_categories_updated_at BEFORE UPDATE ON public.categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_large_table_000_update_timestamp BEFORE UPDATE ON public.large_table_000 FOR EACH ROW EXECUTE FUNCTION update_timestamp_0();

CREATE TRIGGER trg_large_table_001_update_timestamp BEFORE UPDATE ON public.large_table_001 FOR EACH ROW EXECUTE FUNCTION update_timestamp_1();

CREATE TRIGGER trg_large_table_002_update_timestamp BEFORE UPDATE ON public.large_table_002 FOR EACH ROW EXECUTE FUNCTION update_timestamp_2();

CREATE TRIGGER trg_large_table_003_update_timestamp BEFORE UPDATE ON public.large_table_003 FOR EACH ROW EXECUTE FUNCTION update_timestamp_3();

CREATE TRIGGER trg_large_table_004_update_timestamp BEFORE UPDATE ON public.large_table_004 FOR EACH ROW EXECUTE FUNCTION update_timestamp_4();

CREATE TRIGGER trg_large_table_005_update_timestamp BEFORE UPDATE ON public.large_table_005 FOR EACH ROW EXECUTE FUNCTION update_timestamp_5();

CREATE TRIGGER trg_large_table_006_update_timestamp BEFORE UPDATE ON public.large_table_006 FOR EACH ROW EXECUTE FUNCTION update_timestamp_6();

CREATE TRIGGER trg_large_table_007_update_timestamp BEFORE UPDATE ON public.large_table_007 FOR EACH ROW EXECUTE FUNCTION update_timestamp_7();

CREATE TRIGGER trg_large_table_008_update_timestamp BEFORE UPDATE ON public.large_table_008 FOR EACH ROW EXECUTE FUNCTION update_timestamp_8();

CREATE TRIGGER trg_large_table_009_update_timestamp BEFORE UPDATE ON public.large_table_009 FOR EACH ROW EXECUTE FUNCTION update_timestamp_9();

CREATE TRIGGER trg_large_table_010_update_timestamp BEFORE UPDATE ON public.large_table_010 FOR EACH ROW EXECUTE FUNCTION update_timestamp_10();

CREATE TRIGGER trg_large_table_011_update_timestamp BEFORE UPDATE ON public.large_table_011 FOR EACH ROW EXECUTE FUNCTION update_timestamp_11();

CREATE TRIGGER trg_large_table_012_update_timestamp BEFORE UPDATE ON public.large_table_012 FOR EACH ROW EXECUTE FUNCTION update_timestamp_12();

CREATE TRIGGER trg_large_table_013_update_timestamp BEFORE UPDATE ON public.large_table_013 FOR EACH ROW EXECUTE FUNCTION update_timestamp_13();

CREATE TRIGGER trg_large_table_014_update_timestamp BEFORE UPDATE ON public.large_table_014 FOR EACH ROW EXECUTE FUNCTION update_timestamp_14();

CREATE TRIGGER trigger_audit_product_price AFTER UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION audit_product_price_change();

CREATE TRIGGER trigger_update_products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Schema Migrations
INSERT INTO "schema_migrations" (version) VALUES
('20250101000001'),
('20250101000002'),
('20250101000003'),
('20250101000004'),
('20250101000005'),
('20250101000006'),
('20250101000007'),
('20250101000008'),
('20250101000009'),
('20250101000010'),
('20250101000011')
ON CONFLICT DO NOTHING;