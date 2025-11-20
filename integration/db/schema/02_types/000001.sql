CREATE TYPE IF NOT EXISTS address AS (street character varying(255), city character varying(100), state character varying(2), zip_code character varying(10), country character varying(50));

CREATE TYPE IF NOT EXISTS post_status AS ENUM ('draft', 'published', 'archived');

CREATE TYPE IF NOT EXISTS priority_level AS ENUM ('low', 'medium', 'high', 'urgent');

CREATE TYPE IF NOT EXISTS user_role AS ENUM ('admin', 'moderator', 'user', 'guest');

CREATE DOMAIN IF NOT EXISTS email_address AS character varying(255) CHECK (((VALUE)::text ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Z|a-z]{2,}$'::text));

CREATE DOMAIN IF NOT EXISTS percentage AS numeric(5,2) CHECK (((VALUE >= (0)::numeric) AND (VALUE <= (100)::numeric)));

CREATE DOMAIN IF NOT EXISTS positive_integer AS integer CHECK ((VALUE > 0));
