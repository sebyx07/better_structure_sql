CREATE INDEX "index_better_structure_sql_schema_versions_on_content_hash" ON "better_structure_sql_schema_versions" ("content_hash");

CREATE INDEX "index_better_structure_sql_schema_versions_on_created_at" ON "better_structure_sql_schema_versions" ("created_at");

CREATE INDEX "index_comments_on_parent_id" ON "comments" ("parent_id");

CREATE INDEX "index_comments_on_user_id" ON "comments" ("user_id");

CREATE INDEX "index_comments_on_post_id" ON "comments" ("post_id");

CREATE INDEX "index_posts_on_status" ON "posts" ("status");

CREATE INDEX "index_posts_on_user_id" ON "posts" ("user_id");

CREATE INDEX "index_products_on_name" ON "products" ("name");

CREATE INDEX "index_users_on_uuid" ON "users" ("uuid");

CREATE UNIQUE INDEX "index_users_on_email" ON "users" ("email");
