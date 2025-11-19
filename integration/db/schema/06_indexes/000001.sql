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
