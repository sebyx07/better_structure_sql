SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: address; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.address AS (
	street character varying(255),
	city character varying(100),
	state character varying(2),
	zip_code character varying(10),
	country character varying(50)
);


--
-- Name: email_address; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.email_address AS character varying(255)
	CONSTRAINT email_address_check CHECK (((VALUE)::text ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Z|a-z]{2,}$'::text));


--
-- Name: percentage; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.percentage AS numeric(5,2)
	CONSTRAINT percentage_check CHECK (((VALUE >= (0)::numeric) AND (VALUE <= (100)::numeric)));


--
-- Name: positive_integer; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.positive_integer AS integer
	CONSTRAINT positive_integer_check CHECK ((VALUE > 0));


--
-- Name: post_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.post_status AS ENUM (
    'draft',
    'published',
    'archived'
);


--
-- Name: priority_level; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.priority_level AS ENUM (
    'low',
    'medium',
    'high',
    'urgent'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role AS ENUM (
    'admin',
    'moderator',
    'user',
    'guest'
);


--
-- Name: audit_product_price_change(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.audit_product_price_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF OLD.price IS DISTINCT FROM NEW.price THEN
    INSERT INTO product_price_history (product_id, old_price, new_price, changed_at)
    VALUES (NEW.id, OLD.price, NEW.price, CURRENT_TIMESTAMP);
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: calculate_discount_price(numeric, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_discount_price(original_price numeric, discount_percent numeric) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  IF discount_percent IS NULL OR discount_percent = 0 THEN
    RETURN original_price;
  END IF;
  RETURN ROUND(original_price * (1 - discount_percent / 100), 2);
END;
$$;


--
-- Name: calculate_total_0(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_total_0(base_amount numeric) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.0 + 0;
END;
$$;


--
-- Name: calculate_total_1(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_total_1(base_amount numeric) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.1 + 10;
END;
$$;


--
-- Name: calculate_total_2(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_total_2(base_amount numeric) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.2 + 20;
END;
$$;


--
-- Name: calculate_total_3(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_total_3(base_amount numeric) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.3 + 30;
END;
$$;


--
-- Name: calculate_total_4(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_total_4(base_amount numeric) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.4 + 40;
END;
$$;


--
-- Name: calculate_total_5(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_total_5(base_amount numeric) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.5 + 50;
END;
$$;


--
-- Name: calculate_total_6(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_total_6(base_amount numeric) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.6 + 60;
END;
$$;


--
-- Name: calculate_total_7(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_total_7(base_amount numeric) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.7 + 70;
END;
$$;


--
-- Name: calculate_total_8(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_total_8(base_amount numeric) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.8 + 80;
END;
$$;


--
-- Name: calculate_total_9(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_total_9(base_amount numeric) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.9 + 90;
END;
$$;


--
-- Name: update_timestamp_0(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp_0() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: update_timestamp_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp_1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: update_timestamp_10(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp_10() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: update_timestamp_11(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp_11() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: update_timestamp_12(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp_12() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: update_timestamp_13(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp_13() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: update_timestamp_14(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp_14() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: update_timestamp_2(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp_2() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: update_timestamp_3(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp_3() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: update_timestamp_4(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp_4() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: update_timestamp_5(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp_5() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: update_timestamp_6(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp_6() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: update_timestamp_7(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp_7() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: update_timestamp_8(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp_8() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: update_timestamp_9(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp_9() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: uuid_generate_v8(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.uuid_generate_v8() RETURNS uuid
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: validate_email(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_email(email_text text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
BEGIN
  RETURN email_text ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Z|a-z]{2,}$';
END;
$_$;


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id bigint DEFAULT nextval('public.categories_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    description text,
    parent_id integer,
    "position" integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products (
    id bigint DEFAULT nextval('public.products_id_seq'::regclass) NOT NULL,
    category_id bigint NOT NULL,
    name character varying NOT NULL,
    sku character varying NOT NULL,
    description text,
    price numeric(10,2) NOT NULL,
    discount_percentage numeric(5,2),
    stock_quantity integer DEFAULT 0 NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    specifications jsonb DEFAULT '{}'::jsonb,
    tags character varying[] DEFAULT '{}'::character varying[],
    is_active boolean DEFAULT true,
    is_featured boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT check_discount_range CHECK (((discount_percentage >= (0)::numeric) AND (discount_percentage <= (100)::numeric))),
    CONSTRAINT check_price_positive CHECK ((price > (0)::numeric)),
    CONSTRAINT check_stock_non_negative CHECK ((stock_quantity >= 0))
);


--
-- Name: active_products_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.active_products_view AS
 SELECT p.id,
    p.name,
    p.sku,
    p.price,
    p.stock_quantity,
    c.name AS category_name,
    p.created_at
   FROM (public.products p
     JOIN public.categories c ON ((c.id = p.category_id)))
  WHERE (p.is_active = true)
  ORDER BY p.created_at DESC;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: better_structure_sql_schema_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.better_structure_sql_schema_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: better_structure_sql_schema_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.better_structure_sql_schema_versions (
    id bigint DEFAULT nextval('public.better_structure_sql_schema_versions_id_seq'::regclass) NOT NULL,
    content text NOT NULL,
    zip_archive bytea,
    pg_version character varying NOT NULL,
    format_type character varying NOT NULL,
    output_mode character varying NOT NULL,
    content_size bigint NOT NULL,
    line_count integer NOT NULL,
    file_count integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    content_hash character varying(32) NOT NULL,
    CONSTRAINT format_type_check CHECK (((format_type)::text = ANY (ARRAY[('sql'::character varying)::text, ('rb'::character varying)::text]))),
    CONSTRAINT output_mode_check CHECK (((output_mode)::text = ANY (ARRAY[('single_file'::character varying)::text, ('multi_file'::character varying)::text])))
);


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id uuid DEFAULT public.uuid_generate_v8() NOT NULL,
    user_id bigint,
    event_type character varying NOT NULL,
    event_name character varying NOT NULL,
    event_data jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    user_agent character varying,
    occurred_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT check_event_type_not_empty CHECK (((length((event_type)::text) > 0) AND (length((event_name)::text) > 0)))
);


--
-- Name: large_table_000_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_000_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_000; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_000 (
    id bigint DEFAULT nextval('public.large_table_000_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_000_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_001_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_001_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_001; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_001 (
    id bigint DEFAULT nextval('public.large_table_001_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_001_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_002_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_002_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_002; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_002 (
    id bigint DEFAULT nextval('public.large_table_002_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_002_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_003_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_003_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_003; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_003 (
    id bigint DEFAULT nextval('public.large_table_003_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_003_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_004_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_004_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_004; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_004 (
    id bigint DEFAULT nextval('public.large_table_004_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_004_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_005_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_005_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_005; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_005 (
    id bigint DEFAULT nextval('public.large_table_005_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_005_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_006_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_006_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_006; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_006 (
    id bigint DEFAULT nextval('public.large_table_006_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_006_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_007_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_007_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_007; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_007 (
    id bigint DEFAULT nextval('public.large_table_007_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_007_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_008_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_008_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_008; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_008 (
    id bigint DEFAULT nextval('public.large_table_008_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_008_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_009_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_009_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_009; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_009 (
    id bigint DEFAULT nextval('public.large_table_009_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_009_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_010_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_010_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_010; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_010 (
    id bigint DEFAULT nextval('public.large_table_010_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_010_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_011_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_011_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_011; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_011 (
    id bigint DEFAULT nextval('public.large_table_011_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_011_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_012_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_012_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_012; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_012 (
    id bigint DEFAULT nextval('public.large_table_012_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_012_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_013_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_013_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_013; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_013 (
    id bigint DEFAULT nextval('public.large_table_013_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_013_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_014_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_014_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_014; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_014 (
    id bigint DEFAULT nextval('public.large_table_014_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_014_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_015_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_015_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_015; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_015 (
    id bigint DEFAULT nextval('public.large_table_015_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_015_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_016_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_016_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_016; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_016 (
    id bigint DEFAULT nextval('public.large_table_016_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_016_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_017_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_017_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_017; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_017 (
    id bigint DEFAULT nextval('public.large_table_017_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_017_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_018_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_018_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_018; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_018 (
    id bigint DEFAULT nextval('public.large_table_018_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_018_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_019_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_019_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_019; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_019 (
    id bigint DEFAULT nextval('public.large_table_019_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_019_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_020_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_020_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_020; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_020 (
    id bigint DEFAULT nextval('public.large_table_020_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_020_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_021_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_021_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_021; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_021 (
    id bigint DEFAULT nextval('public.large_table_021_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_021_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_022_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_022_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_022; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_022 (
    id bigint DEFAULT nextval('public.large_table_022_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_022_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_023_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_023_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_023; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_023 (
    id bigint DEFAULT nextval('public.large_table_023_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_023_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_024_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_024_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_024; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_024 (
    id bigint DEFAULT nextval('public.large_table_024_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_024_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_025_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_025_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_025; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_025 (
    id bigint DEFAULT nextval('public.large_table_025_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_025_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_026_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_026_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_026; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_026 (
    id bigint DEFAULT nextval('public.large_table_026_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_026_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_027_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_027_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_027; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_027 (
    id bigint DEFAULT nextval('public.large_table_027_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_027_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_028_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_028_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_028; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_028 (
    id bigint DEFAULT nextval('public.large_table_028_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_028_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_029_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_029_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_029; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_029 (
    id bigint DEFAULT nextval('public.large_table_029_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_029_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_030_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_030_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_030; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_030 (
    id bigint DEFAULT nextval('public.large_table_030_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_030_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_031_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_031_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_031; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_031 (
    id bigint DEFAULT nextval('public.large_table_031_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_031_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_032_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_032_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_032; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_032 (
    id bigint DEFAULT nextval('public.large_table_032_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_032_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_033_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_033_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_033; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_033 (
    id bigint DEFAULT nextval('public.large_table_033_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_033_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_034_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_034_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_034; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_034 (
    id bigint DEFAULT nextval('public.large_table_034_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_034_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_035_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_035_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_035; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_035 (
    id bigint DEFAULT nextval('public.large_table_035_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_035_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_036_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_036_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_036; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_036 (
    id bigint DEFAULT nextval('public.large_table_036_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_036_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_037_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_037_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_037; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_037 (
    id bigint DEFAULT nextval('public.large_table_037_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_037_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_038_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_038_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_038; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_038 (
    id bigint DEFAULT nextval('public.large_table_038_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_038_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_039_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_039_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_039; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_039 (
    id bigint DEFAULT nextval('public.large_table_039_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_039_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_040_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_040_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_040; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_040 (
    id bigint DEFAULT nextval('public.large_table_040_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_040_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_041_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_041_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_041; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_041 (
    id bigint DEFAULT nextval('public.large_table_041_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_041_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_042_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_042_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_042; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_042 (
    id bigint DEFAULT nextval('public.large_table_042_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_042_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_043_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_043_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_043; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_043 (
    id bigint DEFAULT nextval('public.large_table_043_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_043_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_044_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_044_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_044; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_044 (
    id bigint DEFAULT nextval('public.large_table_044_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_044_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_045_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_045_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_045; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_045 (
    id bigint DEFAULT nextval('public.large_table_045_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_045_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_046_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_046_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_046; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_046 (
    id bigint DEFAULT nextval('public.large_table_046_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_046_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_047_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_047_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_047; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_047 (
    id bigint DEFAULT nextval('public.large_table_047_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_047_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_048_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_048_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_048; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_048 (
    id bigint DEFAULT nextval('public.large_table_048_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    related_id bigint,
    CONSTRAINT chk_large_table_048_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_table_049_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.large_table_049_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: large_table_049; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.large_table_049 (
    id bigint DEFAULT nextval('public.large_table_049_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    description text,
    status integer DEFAULT 0,
    price numeric(10,2),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    external_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT chk_large_table_049_status CHECK (((status >= 0) AND (status <= 10)))
);


--
-- Name: large_view_00; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_00 AS
 SELECT large_table_000.id,
    large_table_000.name,
    large_table_000.status,
    large_table_000.active,
    large_table_000.created_at
   FROM public.large_table_000
  WHERE (large_table_000.active = true);


--
-- Name: large_view_01; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_01 AS
 SELECT large_table_002.id,
    large_table_002.name,
    large_table_002.status,
    large_table_002.active,
    large_table_002.created_at
   FROM public.large_table_002
  WHERE (large_table_002.active = true);


--
-- Name: large_view_02; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_02 AS
 SELECT large_table_004.id,
    large_table_004.name,
    large_table_004.status,
    large_table_004.active,
    large_table_004.created_at
   FROM public.large_table_004
  WHERE (large_table_004.active = true);


--
-- Name: large_view_03; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_03 AS
 SELECT large_table_006.id,
    large_table_006.name,
    large_table_006.status,
    large_table_006.active,
    large_table_006.created_at
   FROM public.large_table_006
  WHERE (large_table_006.active = true);


--
-- Name: large_view_04; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_04 AS
 SELECT large_table_008.id,
    large_table_008.name,
    large_table_008.status,
    large_table_008.active,
    large_table_008.created_at
   FROM public.large_table_008
  WHERE (large_table_008.active = true);


--
-- Name: large_view_05; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_05 AS
 SELECT large_table_010.id,
    large_table_010.name,
    large_table_010.status,
    large_table_010.active,
    large_table_010.created_at
   FROM public.large_table_010
  WHERE (large_table_010.active = true);


--
-- Name: large_view_06; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_06 AS
 SELECT large_table_012.id,
    large_table_012.name,
    large_table_012.status,
    large_table_012.active,
    large_table_012.created_at
   FROM public.large_table_012
  WHERE (large_table_012.active = true);


--
-- Name: large_view_07; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_07 AS
 SELECT large_table_014.id,
    large_table_014.name,
    large_table_014.status,
    large_table_014.active,
    large_table_014.created_at
   FROM public.large_table_014
  WHERE (large_table_014.active = true);


--
-- Name: large_view_08; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_08 AS
 SELECT large_table_016.id,
    large_table_016.name,
    large_table_016.status,
    large_table_016.active,
    large_table_016.created_at
   FROM public.large_table_016
  WHERE (large_table_016.active = true);


--
-- Name: large_view_09; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_09 AS
 SELECT large_table_018.id,
    large_table_018.name,
    large_table_018.status,
    large_table_018.active,
    large_table_018.created_at
   FROM public.large_table_018
  WHERE (large_table_018.active = true);


--
-- Name: large_view_10; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_10 AS
 SELECT large_table_020.id,
    large_table_020.name,
    large_table_020.status,
    large_table_020.active,
    large_table_020.created_at
   FROM public.large_table_020
  WHERE (large_table_020.active = true);


--
-- Name: large_view_11; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_11 AS
 SELECT large_table_022.id,
    large_table_022.name,
    large_table_022.status,
    large_table_022.active,
    large_table_022.created_at
   FROM public.large_table_022
  WHERE (large_table_022.active = true);


--
-- Name: large_view_12; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_12 AS
 SELECT large_table_024.id,
    large_table_024.name,
    large_table_024.status,
    large_table_024.active,
    large_table_024.created_at
   FROM public.large_table_024
  WHERE (large_table_024.active = true);


--
-- Name: large_view_13; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_13 AS
 SELECT large_table_026.id,
    large_table_026.name,
    large_table_026.status,
    large_table_026.active,
    large_table_026.created_at
   FROM public.large_table_026
  WHERE (large_table_026.active = true);


--
-- Name: large_view_14; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_14 AS
 SELECT large_table_028.id,
    large_table_028.name,
    large_table_028.status,
    large_table_028.active,
    large_table_028.created_at
   FROM public.large_table_028
  WHERE (large_table_028.active = true);


--
-- Name: large_view_15; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_15 AS
 SELECT large_table_030.id,
    large_table_030.name,
    large_table_030.status,
    large_table_030.active,
    large_table_030.created_at
   FROM public.large_table_030
  WHERE (large_table_030.active = true);


--
-- Name: large_view_16; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_16 AS
 SELECT large_table_032.id,
    large_table_032.name,
    large_table_032.status,
    large_table_032.active,
    large_table_032.created_at
   FROM public.large_table_032
  WHERE (large_table_032.active = true);


--
-- Name: large_view_17; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_17 AS
 SELECT large_table_034.id,
    large_table_034.name,
    large_table_034.status,
    large_table_034.active,
    large_table_034.created_at
   FROM public.large_table_034
  WHERE (large_table_034.active = true);


--
-- Name: large_view_18; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_18 AS
 SELECT large_table_036.id,
    large_table_036.name,
    large_table_036.status,
    large_table_036.active,
    large_table_036.created_at
   FROM public.large_table_036
  WHERE (large_table_036.active = true);


--
-- Name: large_view_19; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.large_view_19 AS
 SELECT large_table_038.id,
    large_table_038.name,
    large_table_038.status,
    large_table_038.active,
    large_table_038.created_at
   FROM public.large_table_038
  WHERE (large_table_038.active = true);


--
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.order_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_items (
    id bigint DEFAULT nextval('public.order_items_id_seq'::regclass) NOT NULL,
    order_id bigint NOT NULL,
    product_id bigint NOT NULL,
    quantity integer NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    discount_amount numeric(10,2) DEFAULT 0.0,
    subtotal numeric(10,2) NOT NULL,
    product_snapshot jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT check_item_amounts_positive CHECK (((unit_price > (0)::numeric) AND (discount_amount >= (0)::numeric) AND (subtotal >= (0)::numeric)))
);


--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    id bigint DEFAULT nextval('public.orders_id_seq'::regclass) NOT NULL,
    user_id bigint NOT NULL,
    order_number character varying NOT NULL,
    status public.post_status DEFAULT 'draft'::public.post_status NOT NULL,
    subtotal numeric(10,2) DEFAULT 0.0 NOT NULL,
    tax_amount numeric(10,2) DEFAULT 0.0 NOT NULL,
    shipping_cost numeric(10,2) DEFAULT 0.0 NOT NULL,
    total_amount numeric(10,2) DEFAULT 0.0 NOT NULL,
    shipping_address jsonb DEFAULT '{}'::jsonb,
    billing_address jsonb DEFAULT '{}'::jsonb,
    notes text,
    confirmed_at timestamp without time zone,
    shipped_at timestamp without time zone,
    delivered_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT check_order_amounts_positive CHECK (((subtotal >= (0)::numeric) AND (tax_amount >= (0)::numeric) AND (shipping_cost >= (0)::numeric) AND (total_amount >= (0)::numeric)))
);


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts (
    id bigint DEFAULT nextval('public.posts_id_seq'::regclass) NOT NULL,
    user_id bigint NOT NULL,
    title character varying NOT NULL,
    body text,
    published_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: product_category_summary; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.product_category_summary AS
 SELECT c.id AS category_id,
    c.name AS category_name,
    count(p.id) AS product_count,
    avg(p.price) AS avg_price,
    min(p.price) AS min_price,
    max(p.price) AS max_price,
    sum(p.stock_quantity) AS total_stock
   FROM (public.categories c
     LEFT JOIN public.products p ON (((p.category_id = c.id) AND (p.is_active = true))))
  GROUP BY c.id, c.name
  WITH NO DATA;


--
-- Name: product_price_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_price_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_price_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_price_history (
    id bigint DEFAULT nextval('public.product_price_history_id_seq'::regclass) NOT NULL,
    product_id bigint NOT NULL,
    old_price numeric(10,2),
    new_price numeric(10,2) NOT NULL,
    changed_at timestamp without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id bigint NOT NULL,
    token character varying NOT NULL,
    ip_address inet,
    user_agent character varying,
    expires_at timestamp without time zone NOT NULL,
    last_accessed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint DEFAULT nextval('public.users_id_seq'::regclass) NOT NULL,
    email character varying NOT NULL,
    encrypted_password character varying,
    uuid uuid DEFAULT public.uuid_generate_v4(),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_post_stats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.user_post_stats AS
 SELECT u.id AS user_id,
    u.email,
    count(p.id) AS total_posts,
    count(p.id) FILTER (WHERE (p.published_at IS NOT NULL)) AS published_posts,
    max(p.published_at) AS last_published_at
   FROM (public.users u
     LEFT JOIN public.posts p ON ((p.user_id = u.id)))
  GROUP BY u.id, u.email;


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: better_structure_sql_schema_versions better_structure_sql_schema_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.better_structure_sql_schema_versions
    ADD CONSTRAINT better_structure_sql_schema_versions_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: large_table_000 large_table_000_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_000
    ADD CONSTRAINT large_table_000_pkey PRIMARY KEY (id);


--
-- Name: large_table_001 large_table_001_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_001
    ADD CONSTRAINT large_table_001_pkey PRIMARY KEY (id);


--
-- Name: large_table_002 large_table_002_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_002
    ADD CONSTRAINT large_table_002_pkey PRIMARY KEY (id);


--
-- Name: large_table_003 large_table_003_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_003
    ADD CONSTRAINT large_table_003_pkey PRIMARY KEY (id);


--
-- Name: large_table_004 large_table_004_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_004
    ADD CONSTRAINT large_table_004_pkey PRIMARY KEY (id);


--
-- Name: large_table_005 large_table_005_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_005
    ADD CONSTRAINT large_table_005_pkey PRIMARY KEY (id);


--
-- Name: large_table_006 large_table_006_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_006
    ADD CONSTRAINT large_table_006_pkey PRIMARY KEY (id);


--
-- Name: large_table_007 large_table_007_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_007
    ADD CONSTRAINT large_table_007_pkey PRIMARY KEY (id);


--
-- Name: large_table_008 large_table_008_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_008
    ADD CONSTRAINT large_table_008_pkey PRIMARY KEY (id);


--
-- Name: large_table_009 large_table_009_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_009
    ADD CONSTRAINT large_table_009_pkey PRIMARY KEY (id);


--
-- Name: large_table_010 large_table_010_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_010
    ADD CONSTRAINT large_table_010_pkey PRIMARY KEY (id);


--
-- Name: large_table_011 large_table_011_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_011
    ADD CONSTRAINT large_table_011_pkey PRIMARY KEY (id);


--
-- Name: large_table_012 large_table_012_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_012
    ADD CONSTRAINT large_table_012_pkey PRIMARY KEY (id);


--
-- Name: large_table_013 large_table_013_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_013
    ADD CONSTRAINT large_table_013_pkey PRIMARY KEY (id);


--
-- Name: large_table_014 large_table_014_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_014
    ADD CONSTRAINT large_table_014_pkey PRIMARY KEY (id);


--
-- Name: large_table_015 large_table_015_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_015
    ADD CONSTRAINT large_table_015_pkey PRIMARY KEY (id);


--
-- Name: large_table_016 large_table_016_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_016
    ADD CONSTRAINT large_table_016_pkey PRIMARY KEY (id);


--
-- Name: large_table_017 large_table_017_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_017
    ADD CONSTRAINT large_table_017_pkey PRIMARY KEY (id);


--
-- Name: large_table_018 large_table_018_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_018
    ADD CONSTRAINT large_table_018_pkey PRIMARY KEY (id);


--
-- Name: large_table_019 large_table_019_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_019
    ADD CONSTRAINT large_table_019_pkey PRIMARY KEY (id);


--
-- Name: large_table_020 large_table_020_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_020
    ADD CONSTRAINT large_table_020_pkey PRIMARY KEY (id);


--
-- Name: large_table_021 large_table_021_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_021
    ADD CONSTRAINT large_table_021_pkey PRIMARY KEY (id);


--
-- Name: large_table_022 large_table_022_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_022
    ADD CONSTRAINT large_table_022_pkey PRIMARY KEY (id);


--
-- Name: large_table_023 large_table_023_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_023
    ADD CONSTRAINT large_table_023_pkey PRIMARY KEY (id);


--
-- Name: large_table_024 large_table_024_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_024
    ADD CONSTRAINT large_table_024_pkey PRIMARY KEY (id);


--
-- Name: large_table_025 large_table_025_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_025
    ADD CONSTRAINT large_table_025_pkey PRIMARY KEY (id);


--
-- Name: large_table_026 large_table_026_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_026
    ADD CONSTRAINT large_table_026_pkey PRIMARY KEY (id);


--
-- Name: large_table_027 large_table_027_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_027
    ADD CONSTRAINT large_table_027_pkey PRIMARY KEY (id);


--
-- Name: large_table_028 large_table_028_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_028
    ADD CONSTRAINT large_table_028_pkey PRIMARY KEY (id);


--
-- Name: large_table_029 large_table_029_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_029
    ADD CONSTRAINT large_table_029_pkey PRIMARY KEY (id);


--
-- Name: large_table_030 large_table_030_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_030
    ADD CONSTRAINT large_table_030_pkey PRIMARY KEY (id);


--
-- Name: large_table_031 large_table_031_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_031
    ADD CONSTRAINT large_table_031_pkey PRIMARY KEY (id);


--
-- Name: large_table_032 large_table_032_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_032
    ADD CONSTRAINT large_table_032_pkey PRIMARY KEY (id);


--
-- Name: large_table_033 large_table_033_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_033
    ADD CONSTRAINT large_table_033_pkey PRIMARY KEY (id);


--
-- Name: large_table_034 large_table_034_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_034
    ADD CONSTRAINT large_table_034_pkey PRIMARY KEY (id);


--
-- Name: large_table_035 large_table_035_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_035
    ADD CONSTRAINT large_table_035_pkey PRIMARY KEY (id);


--
-- Name: large_table_036 large_table_036_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_036
    ADD CONSTRAINT large_table_036_pkey PRIMARY KEY (id);


--
-- Name: large_table_037 large_table_037_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_037
    ADD CONSTRAINT large_table_037_pkey PRIMARY KEY (id);


--
-- Name: large_table_038 large_table_038_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_038
    ADD CONSTRAINT large_table_038_pkey PRIMARY KEY (id);


--
-- Name: large_table_039 large_table_039_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_039
    ADD CONSTRAINT large_table_039_pkey PRIMARY KEY (id);


--
-- Name: large_table_040 large_table_040_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_040
    ADD CONSTRAINT large_table_040_pkey PRIMARY KEY (id);


--
-- Name: large_table_041 large_table_041_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_041
    ADD CONSTRAINT large_table_041_pkey PRIMARY KEY (id);


--
-- Name: large_table_042 large_table_042_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_042
    ADD CONSTRAINT large_table_042_pkey PRIMARY KEY (id);


--
-- Name: large_table_043 large_table_043_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_043
    ADD CONSTRAINT large_table_043_pkey PRIMARY KEY (id);


--
-- Name: large_table_044 large_table_044_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_044
    ADD CONSTRAINT large_table_044_pkey PRIMARY KEY (id);


--
-- Name: large_table_045 large_table_045_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_045
    ADD CONSTRAINT large_table_045_pkey PRIMARY KEY (id);


--
-- Name: large_table_046 large_table_046_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_046
    ADD CONSTRAINT large_table_046_pkey PRIMARY KEY (id);


--
-- Name: large_table_047 large_table_047_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_047
    ADD CONSTRAINT large_table_047_pkey PRIMARY KEY (id);


--
-- Name: large_table_048 large_table_048_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_048
    ADD CONSTRAINT large_table_048_pkey PRIMARY KEY (id);


--
-- Name: large_table_049 large_table_049_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_049
    ADD CONSTRAINT large_table_049_pkey PRIMARY KEY (id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: product_price_history product_price_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history
    ADD CONSTRAINT product_price_history_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_large_table_000_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_000_active_status ON public.large_table_000 USING btree (active, status);


--
-- Name: idx_large_table_001_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_001_active_status ON public.large_table_001 USING btree (active, status);


--
-- Name: idx_large_table_002_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_002_active_status ON public.large_table_002 USING btree (active, status);


--
-- Name: idx_large_table_003_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_003_active_status ON public.large_table_003 USING btree (active, status);


--
-- Name: idx_large_table_004_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_004_active_status ON public.large_table_004 USING btree (active, status);


--
-- Name: idx_large_table_005_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_005_active_status ON public.large_table_005 USING btree (active, status);


--
-- Name: idx_large_table_006_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_006_active_status ON public.large_table_006 USING btree (active, status);


--
-- Name: idx_large_table_007_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_007_active_status ON public.large_table_007 USING btree (active, status);


--
-- Name: idx_large_table_008_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_008_active_status ON public.large_table_008 USING btree (active, status);


--
-- Name: idx_large_table_009_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_009_active_status ON public.large_table_009 USING btree (active, status);


--
-- Name: idx_large_table_010_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_010_active_status ON public.large_table_010 USING btree (active, status);


--
-- Name: idx_large_table_011_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_011_active_status ON public.large_table_011 USING btree (active, status);


--
-- Name: idx_large_table_012_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_012_active_status ON public.large_table_012 USING btree (active, status);


--
-- Name: idx_large_table_013_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_013_active_status ON public.large_table_013 USING btree (active, status);


--
-- Name: idx_large_table_014_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_014_active_status ON public.large_table_014 USING btree (active, status);


--
-- Name: idx_large_table_015_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_015_active_status ON public.large_table_015 USING btree (active, status);


--
-- Name: idx_large_table_016_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_016_active_status ON public.large_table_016 USING btree (active, status);


--
-- Name: idx_large_table_017_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_017_active_status ON public.large_table_017 USING btree (active, status);


--
-- Name: idx_large_table_018_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_018_active_status ON public.large_table_018 USING btree (active, status);


--
-- Name: idx_large_table_019_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_019_active_status ON public.large_table_019 USING btree (active, status);


--
-- Name: idx_large_table_020_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_020_active_status ON public.large_table_020 USING btree (active, status);


--
-- Name: idx_large_table_021_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_021_active_status ON public.large_table_021 USING btree (active, status);


--
-- Name: idx_large_table_022_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_022_active_status ON public.large_table_022 USING btree (active, status);


--
-- Name: idx_large_table_023_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_023_active_status ON public.large_table_023 USING btree (active, status);


--
-- Name: idx_large_table_024_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_024_active_status ON public.large_table_024 USING btree (active, status);


--
-- Name: idx_large_table_025_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_025_active_status ON public.large_table_025 USING btree (active, status);


--
-- Name: idx_large_table_026_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_026_active_status ON public.large_table_026 USING btree (active, status);


--
-- Name: idx_large_table_027_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_027_active_status ON public.large_table_027 USING btree (active, status);


--
-- Name: idx_large_table_028_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_028_active_status ON public.large_table_028 USING btree (active, status);


--
-- Name: idx_large_table_029_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_029_active_status ON public.large_table_029 USING btree (active, status);


--
-- Name: idx_large_table_030_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_030_active_status ON public.large_table_030 USING btree (active, status);


--
-- Name: idx_large_table_031_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_031_active_status ON public.large_table_031 USING btree (active, status);


--
-- Name: idx_large_table_032_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_032_active_status ON public.large_table_032 USING btree (active, status);


--
-- Name: idx_large_table_033_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_033_active_status ON public.large_table_033 USING btree (active, status);


--
-- Name: idx_large_table_034_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_034_active_status ON public.large_table_034 USING btree (active, status);


--
-- Name: idx_large_table_035_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_035_active_status ON public.large_table_035 USING btree (active, status);


--
-- Name: idx_large_table_036_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_036_active_status ON public.large_table_036 USING btree (active, status);


--
-- Name: idx_large_table_037_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_037_active_status ON public.large_table_037 USING btree (active, status);


--
-- Name: idx_large_table_038_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_038_active_status ON public.large_table_038 USING btree (active, status);


--
-- Name: idx_large_table_039_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_039_active_status ON public.large_table_039 USING btree (active, status);


--
-- Name: idx_large_table_040_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_040_active_status ON public.large_table_040 USING btree (active, status);


--
-- Name: idx_large_table_041_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_041_active_status ON public.large_table_041 USING btree (active, status);


--
-- Name: idx_large_table_042_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_042_active_status ON public.large_table_042 USING btree (active, status);


--
-- Name: idx_large_table_043_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_043_active_status ON public.large_table_043 USING btree (active, status);


--
-- Name: idx_large_table_044_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_044_active_status ON public.large_table_044 USING btree (active, status);


--
-- Name: idx_large_table_045_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_045_active_status ON public.large_table_045 USING btree (active, status);


--
-- Name: idx_large_table_046_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_046_active_status ON public.large_table_046 USING btree (active, status);


--
-- Name: idx_large_table_047_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_047_active_status ON public.large_table_047 USING btree (active, status);


--
-- Name: idx_large_table_048_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_048_active_status ON public.large_table_048 USING btree (active, status);


--
-- Name: idx_large_table_049_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_large_table_049_active_status ON public.large_table_049 USING btree (active, status);


--
-- Name: index_active_products_unique_sku; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_products_unique_sku ON public.products USING btree (sku) WHERE (is_active = true);


--
-- Name: index_better_structure_sql_schema_versions_on_content_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_better_structure_sql_schema_versions_on_content_hash ON public.better_structure_sql_schema_versions USING btree (content_hash);


--
-- Name: index_better_structure_sql_schema_versions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_better_structure_sql_schema_versions_on_created_at ON public.better_structure_sql_schema_versions USING btree (created_at DESC);


--
-- Name: index_better_structure_sql_schema_versions_on_output_mode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_better_structure_sql_schema_versions_on_output_mode ON public.better_structure_sql_schema_versions USING btree (output_mode);


--
-- Name: index_categories_on_lower_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_categories_on_lower_name ON public.categories USING btree (lower((name)::text));


--
-- Name: index_categories_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_categories_on_parent_id ON public.categories USING btree (parent_id);


--
-- Name: index_categories_on_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_categories_on_position ON public.categories USING btree ("position");


--
-- Name: index_categories_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_categories_on_slug ON public.categories USING btree (slug);


--
-- Name: index_events_on_event_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_event_data ON public.events USING gin (event_data);


--
-- Name: index_events_on_event_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_event_name ON public.events USING btree (event_name);


--
-- Name: index_events_on_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_event_type ON public.events USING btree (event_type);


--
-- Name: index_events_on_occurred_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_occurred_at ON public.events USING brin (occurred_at);


--
-- Name: index_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_user_id ON public.events USING btree (user_id);


--
-- Name: index_events_on_user_id_and_occurred_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_user_id_and_occurred_at ON public.events USING btree (user_id, occurred_at);


--
-- Name: index_large_table_000_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_000_on_name ON public.large_table_000 USING btree (name);


--
-- Name: index_large_table_000_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_000_on_status ON public.large_table_000 USING btree (status);


--
-- Name: index_large_table_001_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_001_on_name ON public.large_table_001 USING btree (name);


--
-- Name: index_large_table_001_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_001_on_status ON public.large_table_001 USING btree (status);


--
-- Name: index_large_table_002_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_002_on_name ON public.large_table_002 USING btree (name);


--
-- Name: index_large_table_002_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_002_on_status ON public.large_table_002 USING btree (status);


--
-- Name: index_large_table_003_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_003_on_name ON public.large_table_003 USING btree (name);


--
-- Name: index_large_table_003_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_003_on_status ON public.large_table_003 USING btree (status);


--
-- Name: index_large_table_004_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_004_on_name ON public.large_table_004 USING btree (name);


--
-- Name: index_large_table_004_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_004_on_status ON public.large_table_004 USING btree (status);


--
-- Name: index_large_table_005_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_005_on_name ON public.large_table_005 USING btree (name);


--
-- Name: index_large_table_005_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_005_on_status ON public.large_table_005 USING btree (status);


--
-- Name: index_large_table_006_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_006_on_name ON public.large_table_006 USING btree (name);


--
-- Name: index_large_table_006_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_006_on_status ON public.large_table_006 USING btree (status);


--
-- Name: index_large_table_007_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_007_on_name ON public.large_table_007 USING btree (name);


--
-- Name: index_large_table_007_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_007_on_status ON public.large_table_007 USING btree (status);


--
-- Name: index_large_table_008_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_008_on_name ON public.large_table_008 USING btree (name);


--
-- Name: index_large_table_008_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_008_on_status ON public.large_table_008 USING btree (status);


--
-- Name: index_large_table_009_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_009_on_name ON public.large_table_009 USING btree (name);


--
-- Name: index_large_table_009_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_009_on_status ON public.large_table_009 USING btree (status);


--
-- Name: index_large_table_010_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_010_on_name ON public.large_table_010 USING btree (name);


--
-- Name: index_large_table_010_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_010_on_status ON public.large_table_010 USING btree (status);


--
-- Name: index_large_table_011_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_011_on_name ON public.large_table_011 USING btree (name);


--
-- Name: index_large_table_011_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_011_on_status ON public.large_table_011 USING btree (status);


--
-- Name: index_large_table_012_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_012_on_name ON public.large_table_012 USING btree (name);


--
-- Name: index_large_table_012_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_012_on_status ON public.large_table_012 USING btree (status);


--
-- Name: index_large_table_013_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_013_on_name ON public.large_table_013 USING btree (name);


--
-- Name: index_large_table_013_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_013_on_status ON public.large_table_013 USING btree (status);


--
-- Name: index_large_table_014_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_014_on_name ON public.large_table_014 USING btree (name);


--
-- Name: index_large_table_014_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_014_on_status ON public.large_table_014 USING btree (status);


--
-- Name: index_large_table_015_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_015_on_name ON public.large_table_015 USING btree (name);


--
-- Name: index_large_table_015_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_015_on_status ON public.large_table_015 USING btree (status);


--
-- Name: index_large_table_016_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_016_on_name ON public.large_table_016 USING btree (name);


--
-- Name: index_large_table_016_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_016_on_status ON public.large_table_016 USING btree (status);


--
-- Name: index_large_table_017_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_017_on_name ON public.large_table_017 USING btree (name);


--
-- Name: index_large_table_017_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_017_on_status ON public.large_table_017 USING btree (status);


--
-- Name: index_large_table_018_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_018_on_name ON public.large_table_018 USING btree (name);


--
-- Name: index_large_table_018_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_018_on_status ON public.large_table_018 USING btree (status);


--
-- Name: index_large_table_019_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_019_on_name ON public.large_table_019 USING btree (name);


--
-- Name: index_large_table_019_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_019_on_status ON public.large_table_019 USING btree (status);


--
-- Name: index_large_table_020_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_020_on_name ON public.large_table_020 USING btree (name);


--
-- Name: index_large_table_020_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_020_on_status ON public.large_table_020 USING btree (status);


--
-- Name: index_large_table_021_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_021_on_name ON public.large_table_021 USING btree (name);


--
-- Name: index_large_table_021_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_021_on_status ON public.large_table_021 USING btree (status);


--
-- Name: index_large_table_022_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_022_on_name ON public.large_table_022 USING btree (name);


--
-- Name: index_large_table_022_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_022_on_status ON public.large_table_022 USING btree (status);


--
-- Name: index_large_table_023_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_023_on_name ON public.large_table_023 USING btree (name);


--
-- Name: index_large_table_023_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_023_on_status ON public.large_table_023 USING btree (status);


--
-- Name: index_large_table_024_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_024_on_name ON public.large_table_024 USING btree (name);


--
-- Name: index_large_table_024_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_024_on_status ON public.large_table_024 USING btree (status);


--
-- Name: index_large_table_025_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_025_on_name ON public.large_table_025 USING btree (name);


--
-- Name: index_large_table_025_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_025_on_status ON public.large_table_025 USING btree (status);


--
-- Name: index_large_table_026_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_026_on_name ON public.large_table_026 USING btree (name);


--
-- Name: index_large_table_026_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_026_on_status ON public.large_table_026 USING btree (status);


--
-- Name: index_large_table_027_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_027_on_name ON public.large_table_027 USING btree (name);


--
-- Name: index_large_table_027_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_027_on_status ON public.large_table_027 USING btree (status);


--
-- Name: index_large_table_028_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_028_on_name ON public.large_table_028 USING btree (name);


--
-- Name: index_large_table_028_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_028_on_status ON public.large_table_028 USING btree (status);


--
-- Name: index_large_table_029_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_029_on_name ON public.large_table_029 USING btree (name);


--
-- Name: index_large_table_029_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_029_on_status ON public.large_table_029 USING btree (status);


--
-- Name: index_large_table_030_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_030_on_name ON public.large_table_030 USING btree (name);


--
-- Name: index_large_table_030_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_030_on_status ON public.large_table_030 USING btree (status);


--
-- Name: index_large_table_031_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_031_on_name ON public.large_table_031 USING btree (name);


--
-- Name: index_large_table_031_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_031_on_status ON public.large_table_031 USING btree (status);


--
-- Name: index_large_table_032_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_032_on_name ON public.large_table_032 USING btree (name);


--
-- Name: index_large_table_032_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_032_on_status ON public.large_table_032 USING btree (status);


--
-- Name: index_large_table_033_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_033_on_name ON public.large_table_033 USING btree (name);


--
-- Name: index_large_table_033_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_033_on_status ON public.large_table_033 USING btree (status);


--
-- Name: index_large_table_034_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_034_on_name ON public.large_table_034 USING btree (name);


--
-- Name: index_large_table_034_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_034_on_status ON public.large_table_034 USING btree (status);


--
-- Name: index_large_table_035_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_035_on_name ON public.large_table_035 USING btree (name);


--
-- Name: index_large_table_035_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_035_on_status ON public.large_table_035 USING btree (status);


--
-- Name: index_large_table_036_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_036_on_name ON public.large_table_036 USING btree (name);


--
-- Name: index_large_table_036_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_036_on_status ON public.large_table_036 USING btree (status);


--
-- Name: index_large_table_037_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_037_on_name ON public.large_table_037 USING btree (name);


--
-- Name: index_large_table_037_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_037_on_status ON public.large_table_037 USING btree (status);


--
-- Name: index_large_table_038_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_038_on_name ON public.large_table_038 USING btree (name);


--
-- Name: index_large_table_038_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_038_on_status ON public.large_table_038 USING btree (status);


--
-- Name: index_large_table_039_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_039_on_name ON public.large_table_039 USING btree (name);


--
-- Name: index_large_table_039_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_039_on_status ON public.large_table_039 USING btree (status);


--
-- Name: index_large_table_040_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_040_on_name ON public.large_table_040 USING btree (name);


--
-- Name: index_large_table_040_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_040_on_status ON public.large_table_040 USING btree (status);


--
-- Name: index_large_table_041_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_041_on_name ON public.large_table_041 USING btree (name);


--
-- Name: index_large_table_041_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_041_on_status ON public.large_table_041 USING btree (status);


--
-- Name: index_large_table_042_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_042_on_name ON public.large_table_042 USING btree (name);


--
-- Name: index_large_table_042_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_042_on_status ON public.large_table_042 USING btree (status);


--
-- Name: index_large_table_043_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_043_on_name ON public.large_table_043 USING btree (name);


--
-- Name: index_large_table_043_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_043_on_status ON public.large_table_043 USING btree (status);


--
-- Name: index_large_table_044_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_044_on_name ON public.large_table_044 USING btree (name);


--
-- Name: index_large_table_044_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_044_on_status ON public.large_table_044 USING btree (status);


--
-- Name: index_large_table_045_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_045_on_name ON public.large_table_045 USING btree (name);


--
-- Name: index_large_table_045_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_045_on_status ON public.large_table_045 USING btree (status);


--
-- Name: index_large_table_046_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_046_on_name ON public.large_table_046 USING btree (name);


--
-- Name: index_large_table_046_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_046_on_status ON public.large_table_046 USING btree (status);


--
-- Name: index_large_table_047_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_047_on_name ON public.large_table_047 USING btree (name);


--
-- Name: index_large_table_047_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_047_on_status ON public.large_table_047 USING btree (status);


--
-- Name: index_large_table_048_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_048_on_name ON public.large_table_048 USING btree (name);


--
-- Name: index_large_table_048_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_048_on_status ON public.large_table_048 USING btree (status);


--
-- Name: index_large_table_049_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_049_on_name ON public.large_table_049 USING btree (name);


--
-- Name: index_large_table_049_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_large_table_049_on_status ON public.large_table_049 USING btree (status);


--
-- Name: index_order_items_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_items_on_order_id ON public.order_items USING btree (order_id);


--
-- Name: index_order_items_on_order_id_and_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_order_items_on_order_id_and_product_id ON public.order_items USING btree (order_id, product_id);


--
-- Name: index_order_items_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_items_on_product_id ON public.order_items USING btree (product_id);


--
-- Name: index_orders_created_at_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_created_at_brin ON public.orders USING brin (created_at);


--
-- Name: index_orders_on_confirmed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_confirmed_at ON public.orders USING btree (confirmed_at) WHERE (confirmed_at IS NOT NULL);


--
-- Name: index_orders_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_created_at ON public.orders USING btree (created_at);


--
-- Name: index_orders_on_order_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_orders_on_order_number ON public.orders USING btree (order_number);


--
-- Name: index_orders_on_shipped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_shipped_at ON public.orders USING btree (shipped_at) WHERE (shipped_at IS NOT NULL);


--
-- Name: index_orders_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_status ON public.orders USING btree (status);


--
-- Name: index_orders_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_user_id ON public.orders USING btree (user_id);


--
-- Name: index_orders_shipping_address_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_shipping_address_path ON public.orders USING gin (shipping_address jsonb_path_ops);


--
-- Name: index_posts_on_published_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_published_at ON public.posts USING btree (published_at) WHERE (published_at IS NOT NULL);


--
-- Name: index_posts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_user_id ON public.posts USING btree (user_id);


--
-- Name: index_product_category_summary_on_avg_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_category_summary_on_avg_price ON public.product_category_summary USING btree (avg_price);


--
-- Name: index_product_category_summary_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_product_category_summary_on_category_id ON public.product_category_summary USING btree (category_id);


--
-- Name: index_product_price_history_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_price_history_on_product_id ON public.product_price_history USING btree (product_id);


--
-- Name: index_product_price_history_on_product_id_and_changed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_price_history_on_product_id_and_changed_at ON public.product_price_history USING btree (product_id, changed_at);


--
-- Name: index_products_fulltext_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_fulltext_search ON public.products USING gin (to_tsvector('english'::regconfig, (((COALESCE(name, ''::character varying))::text || ' '::text) || COALESCE(description, ''::text))));


--
-- Name: index_products_metadata_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_metadata_path ON public.products USING gin (metadata jsonb_path_ops);


--
-- Name: index_products_on_available_items; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_available_items ON public.products USING btree (category_id, is_active, price) WHERE ((is_active = true) AND (stock_quantity > 0));


--
-- Name: index_products_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_category_id ON public.products USING btree (category_id);


--
-- Name: index_products_on_category_id_and_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_category_id_and_price ON public.products USING btree (category_id, price);


--
-- Name: index_products_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_created_at ON public.products USING btree (created_at);


--
-- Name: index_products_on_discounted_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_discounted_price ON public.products USING btree (((price * ((1)::numeric - (COALESCE(discount_percentage, (0)::numeric) / (100)::numeric)))));


--
-- Name: index_products_on_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_is_active ON public.products USING btree (is_active);


--
-- Name: index_products_on_is_featured; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_is_featured ON public.products USING btree (is_featured) WHERE (is_featured = true);


--
-- Name: index_products_on_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_metadata ON public.products USING gin (metadata);


--
-- Name: index_products_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_name ON public.products USING btree (name);


--
-- Name: index_products_on_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_price ON public.products USING btree (price);


--
-- Name: index_products_on_sku; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_products_on_sku ON public.products USING btree (sku);


--
-- Name: index_products_on_specifications; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_specifications ON public.products USING gin (specifications);


--
-- Name: index_products_on_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_tags ON public.products USING gin (tags);


--
-- Name: index_sessions_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_expires_at ON public.sessions USING btree (expires_at);


--
-- Name: index_sessions_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sessions_on_token ON public.sessions USING btree (token);


--
-- Name: index_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_id ON public.sessions USING btree (user_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_lower_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_lower_email ON public.users USING btree (lower((email)::text));


--
-- Name: index_users_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_uuid ON public.users USING btree (uuid);


--
-- Name: large_table_000 trg_large_table_000_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_large_table_000_update_timestamp BEFORE UPDATE ON public.large_table_000 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp_0();


--
-- Name: large_table_001 trg_large_table_001_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_large_table_001_update_timestamp BEFORE UPDATE ON public.large_table_001 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp_1();


--
-- Name: large_table_002 trg_large_table_002_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_large_table_002_update_timestamp BEFORE UPDATE ON public.large_table_002 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp_2();


--
-- Name: large_table_003 trg_large_table_003_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_large_table_003_update_timestamp BEFORE UPDATE ON public.large_table_003 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp_3();


--
-- Name: large_table_004 trg_large_table_004_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_large_table_004_update_timestamp BEFORE UPDATE ON public.large_table_004 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp_4();


--
-- Name: large_table_005 trg_large_table_005_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_large_table_005_update_timestamp BEFORE UPDATE ON public.large_table_005 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp_5();


--
-- Name: large_table_006 trg_large_table_006_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_large_table_006_update_timestamp BEFORE UPDATE ON public.large_table_006 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp_6();


--
-- Name: large_table_007 trg_large_table_007_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_large_table_007_update_timestamp BEFORE UPDATE ON public.large_table_007 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp_7();


--
-- Name: large_table_008 trg_large_table_008_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_large_table_008_update_timestamp BEFORE UPDATE ON public.large_table_008 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp_8();


--
-- Name: large_table_009 trg_large_table_009_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_large_table_009_update_timestamp BEFORE UPDATE ON public.large_table_009 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp_9();


--
-- Name: large_table_010 trg_large_table_010_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_large_table_010_update_timestamp BEFORE UPDATE ON public.large_table_010 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp_10();


--
-- Name: large_table_011 trg_large_table_011_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_large_table_011_update_timestamp BEFORE UPDATE ON public.large_table_011 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp_11();


--
-- Name: large_table_012 trg_large_table_012_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_large_table_012_update_timestamp BEFORE UPDATE ON public.large_table_012 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp_12();


--
-- Name: large_table_013 trg_large_table_013_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_large_table_013_update_timestamp BEFORE UPDATE ON public.large_table_013 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp_13();


--
-- Name: large_table_014 trg_large_table_014_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_large_table_014_update_timestamp BEFORE UPDATE ON public.large_table_014 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp_14();


--
-- Name: products trigger_audit_product_price; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_audit_product_price AFTER UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.audit_product_price_change();


--
-- Name: categories trigger_update_categories_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_categories_updated_at BEFORE UPDATE ON public.categories FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: products trigger_update_products_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: large_table_042 fk_rails_061295adfe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_042
    ADD CONSTRAINT fk_rails_061295adfe FOREIGN KEY (related_id) REFERENCES public.large_table_043(id);


--
-- Name: large_table_006 fk_rails_0a2a5c7700; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_006
    ADD CONSTRAINT fk_rails_0a2a5c7700 FOREIGN KEY (related_id) REFERENCES public.large_table_007(id);


--
-- Name: events fk_rails_0cb5590091; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT fk_rails_0cb5590091 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: large_table_002 fk_rails_10d4c7857f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_002
    ADD CONSTRAINT fk_rails_10d4c7857f FOREIGN KEY (related_id) REFERENCES public.large_table_003(id);


--
-- Name: large_table_036 fk_rails_17434a2d19; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_036
    ADD CONSTRAINT fk_rails_17434a2d19 FOREIGN KEY (related_id) REFERENCES public.large_table_037(id);


--
-- Name: large_table_022 fk_rails_1750dd1c8c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_022
    ADD CONSTRAINT fk_rails_1750dd1c8c FOREIGN KEY (related_id) REFERENCES public.large_table_023(id);


--
-- Name: large_table_044 fk_rails_1adeeaa1a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_044
    ADD CONSTRAINT fk_rails_1adeeaa1a6 FOREIGN KEY (related_id) REFERENCES public.large_table_045(id);


--
-- Name: large_table_034 fk_rails_2b45e03f7f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_034
    ADD CONSTRAINT fk_rails_2b45e03f7f FOREIGN KEY (related_id) REFERENCES public.large_table_035(id);


--
-- Name: large_table_008 fk_rails_2fe8a3e5c2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_008
    ADD CONSTRAINT fk_rails_2fe8a3e5c2 FOREIGN KEY (related_id) REFERENCES public.large_table_009(id);


--
-- Name: large_table_028 fk_rails_37310c7788; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_028
    ADD CONSTRAINT fk_rails_37310c7788 FOREIGN KEY (related_id) REFERENCES public.large_table_029(id);


--
-- Name: large_table_032 fk_rails_3b295accd5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_032
    ADD CONSTRAINT fk_rails_3b295accd5 FOREIGN KEY (related_id) REFERENCES public.large_table_033(id);


--
-- Name: large_table_004 fk_rails_403f789646; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_004
    ADD CONSTRAINT fk_rails_403f789646 FOREIGN KEY (related_id) REFERENCES public.large_table_005(id);


--
-- Name: large_table_020 fk_rails_4059e67133; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_020
    ADD CONSTRAINT fk_rails_4059e67133 FOREIGN KEY (related_id) REFERENCES public.large_table_021(id);


--
-- Name: large_table_000 fk_rails_4a0fe673f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_000
    ADD CONSTRAINT fk_rails_4a0fe673f1 FOREIGN KEY (related_id) REFERENCES public.large_table_001(id);


--
-- Name: large_table_038 fk_rails_4ce638a77b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_038
    ADD CONSTRAINT fk_rails_4ce638a77b FOREIGN KEY (related_id) REFERENCES public.large_table_039(id);


--
-- Name: large_table_048 fk_rails_4e9b16baa9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_048
    ADD CONSTRAINT fk_rails_4e9b16baa9 FOREIGN KEY (related_id) REFERENCES public.large_table_049(id);


--
-- Name: posts fk_rails_5b5ddfd518; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT fk_rails_5b5ddfd518 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: large_table_024 fk_rails_64b98564cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_024
    ADD CONSTRAINT fk_rails_64b98564cb FOREIGN KEY (related_id) REFERENCES public.large_table_025(id);


--
-- Name: large_table_016 fk_rails_6ff3f374a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_016
    ADD CONSTRAINT fk_rails_6ff3f374a2 FOREIGN KEY (related_id) REFERENCES public.large_table_017(id);


--
-- Name: sessions fk_rails_758836b4f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_rails_758836b4f0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: categories fk_rails_82f48f7407; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT fk_rails_82f48f7407 FOREIGN KEY (parent_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- Name: large_table_010 fk_rails_8baf10fabf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_010
    ADD CONSTRAINT fk_rails_8baf10fabf FOREIGN KEY (related_id) REFERENCES public.large_table_011(id);


--
-- Name: large_table_012 fk_rails_8ff9e73b1c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_012
    ADD CONSTRAINT fk_rails_8ff9e73b1c FOREIGN KEY (related_id) REFERENCES public.large_table_013(id);


--
-- Name: large_table_018 fk_rails_95217f3d00; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_018
    ADD CONSTRAINT fk_rails_95217f3d00 FOREIGN KEY (related_id) REFERENCES public.large_table_019(id);


--
-- Name: large_table_026 fk_rails_a24e0ff80a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_026
    ADD CONSTRAINT fk_rails_a24e0ff80a FOREIGN KEY (related_id) REFERENCES public.large_table_027(id);


--
-- Name: large_table_030 fk_rails_aa888a6236; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_030
    ADD CONSTRAINT fk_rails_aa888a6236 FOREIGN KEY (related_id) REFERENCES public.large_table_031(id);


--
-- Name: product_price_history fk_rails_b70a9e116e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history
    ADD CONSTRAINT fk_rails_b70a9e116e FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: large_table_014 fk_rails_c23a51d6d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_014
    ADD CONSTRAINT fk_rails_c23a51d6d3 FOREIGN KEY (related_id) REFERENCES public.large_table_015(id);


--
-- Name: large_table_040 fk_rails_cd44c375bc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_040
    ADD CONSTRAINT fk_rails_cd44c375bc FOREIGN KEY (related_id) REFERENCES public.large_table_041(id);


--
-- Name: order_items fk_rails_e3cb28f071; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT fk_rails_e3cb28f071 FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: large_table_046 fk_rails_e606c0a7e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.large_table_046
    ADD CONSTRAINT fk_rails_e606c0a7e9 FOREIGN KEY (related_id) REFERENCES public.large_table_047(id);


--
-- Name: order_items fk_rails_f1a29ddd47; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT fk_rails_f1a29ddd47 FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE RESTRICT;


--
-- Name: orders fk_rails_f868b47f6a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_f868b47f6a FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: products fk_rails_fb915499a4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT fk_rails_fb915499a4 FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20250120000001'),
('20250101000011'),
('20250101000010'),
('20250101000009'),
('20250101000008'),
('20250101000007'),
('20250101000006'),
('20250101000005'),
('20250101000004'),
('20250101000003'),
('20250101000002'),
('20250101000001');

