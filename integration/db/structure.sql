SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

-- Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

SET search_path TO public;

-- Sequences
CREATE SEQUENCE better_structure_sql_schema_versions_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE posts_id_seq
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
  pg_version varchar NOT NULL,
  format_type varchar NOT NULL,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id)
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

CREATE TABLE schema_migrations (
  version varchar NOT NULL,
  PRIMARY KEY (version)
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
CREATE INDEX index_better_structure_sql_schema_versions_on_created_at ON public.better_structure_sql_schema_versions USING btree (created_at);
CREATE INDEX index_posts_on_published_at ON public.posts USING btree (published_at) WHERE (published_at IS NOT NULL);
CREATE INDEX index_posts_on_user_id ON public.posts USING btree (user_id);
CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);
CREATE INDEX index_users_on_uuid ON public.users USING btree (uuid);

-- Foreign Keys
ALTER TABLE posts ADD CONSTRAINT fk_rails_5b5ddfd518 FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE;

-- Schema Migrations
INSERT INTO "schema_migrations" (version) VALUES
('20250101000001'),
('20250101000002'),
('20250101000003')
ON CONFLICT DO NOTHING;INSERT INTO "schema_migrations" (version) VALUES
('20250101000003'),
('20250101000002'),
('20250101000001');

