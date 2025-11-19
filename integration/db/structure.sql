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

-- Sequences
CREATE SEQUENCE better_structure_sql_schema_versions_id_seq
  START WITH 1
  MINVALUE 1
  MAXVALUE 9223372036854775807;
CREATE SEQUENCE categories_id_seq
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
  pg_version varchar NOT NULL,
  format_type varchar NOT NULL,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id)
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
CREATE INDEX index_categories_on_lower_name ON public.categories USING btree (lower((name)::text));
CREATE INDEX index_categories_on_parent_id ON public.categories USING btree (parent_id);
CREATE INDEX index_categories_on_position ON public.categories USING btree ("position");
CREATE UNIQUE INDEX index_categories_on_slug ON public.categories USING btree (slug);
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
CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);
CREATE INDEX index_users_on_lower_email ON public.users USING btree (lower((email)::text));
CREATE INDEX index_users_on_uuid ON public.users USING btree (uuid);

-- Foreign Keys
ALTER TABLE categories ADD CONSTRAINT fk_rails_82f48f7407 FOREIGN KEY (parent_id) REFERENCES categories (id) ON DELETE CASCADE;
ALTER TABLE order_items ADD CONSTRAINT fk_rails_e3cb28f071 FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE;
ALTER TABLE order_items ADD CONSTRAINT fk_rails_f1a29ddd47 FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT;
ALTER TABLE orders ADD CONSTRAINT fk_rails_f868b47f6a FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT;
ALTER TABLE posts ADD CONSTRAINT fk_rails_5b5ddfd518 FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE;
ALTER TABLE product_price_history ADD CONSTRAINT fk_rails_b70a9e116e FOREIGN KEY (product_id) REFERENCES products (id);
ALTER TABLE products ADD CONSTRAINT fk_rails_fb915499a4 FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT;

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

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
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
('20250101000009')
ON CONFLICT DO NOTHING;INSERT INTO "schema_migrations" (version) VALUES
('20250101000009'),
('20250101000008'),
('20250101000007'),
('20250101000006'),
('20250101000005'),
('20250101000004'),
('20250101000003'),
('20250101000002'),
('20250101000001');

