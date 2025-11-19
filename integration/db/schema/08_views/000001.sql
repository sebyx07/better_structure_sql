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
