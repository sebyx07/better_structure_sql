CREATE INDEX `index_better_structure_sql_schema_versions_on_content_hash` ON `better_structure_sql_schema_versions` (`content_hash`);

CREATE INDEX `index_better_structure_sql_schema_versions_on_created_at` ON `better_structure_sql_schema_versions` (`created_at`);

CREATE INDEX `index_better_structure_sql_schema_versions_on_output_mode` ON `better_structure_sql_schema_versions` (`output_mode`);

CREATE UNIQUE INDEX `index_categories_on_slug` ON `categories` (`slug`);

CREATE INDEX `index_order_items_on_order_id` ON `order_items` (`order_id`);

CREATE UNIQUE INDEX `index_order_items_on_order_id_and_product_id` ON `order_items` (`order_id`, `product_id`);

CREATE INDEX `index_order_items_on_product_id` ON `order_items` (`product_id`);

CREATE INDEX `index_orders_on_status` ON `orders` (`status`);

CREATE INDEX `index_orders_on_user_id` ON `orders` (`user_id`);

CREATE INDEX `index_posts_on_status` ON `posts` (`status`);

CREATE INDEX `index_posts_on_user_id` ON `posts` (`user_id`);

CREATE INDEX `index_products_on_category_id` ON `products` (`category_id`);

CREATE INDEX `index_products_on_name` ON `products` (`name`);

CREATE INDEX `index_products_on_price` ON `products` (`price`);

CREATE UNIQUE INDEX `index_users_on_email` ON `users` (`email`);

CREATE INDEX `index_users_on_uuid` ON `users` (`uuid`);
