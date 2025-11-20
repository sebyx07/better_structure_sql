COMMENT ON TABLE "posts" IS 'Blog posts created by users';

COMMENT ON TABLE "products" IS 'Product catalog with pricing and inventory';

COMMENT ON TABLE "users" IS 'User accounts and authentication data';

COMMENT ON COLUMN "posts"."title" IS 'Post title displayed in search results and feeds';

COMMENT ON COLUMN "posts"."body" IS 'Full post content in Markdown format';

COMMENT ON COLUMN "products"."name" IS 'Product name displayed to customers';

COMMENT ON COLUMN "products"."price" IS 'Current selling price in cents (to avoid floating point errors)';

COMMENT ON COLUMN "users"."email" IS 'Unique email address for authentication';

COMMENT ON COLUMN "users"."encrypted_password" IS 'BCrypt hashed password for secure storage';

COMMENT ON INDEX "index_users_on_email" IS 'Unique index for fast email lookup during authentication';
