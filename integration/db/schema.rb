# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_01_01_000010) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "uuid-ossp"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "post_status", ["draft", "published", "archived"]
  create_enum "priority_level", ["low", "medium", "high", "urgent"]
  create_enum "user_role", ["admin", "moderator", "user", "guest"]

  create_table "better_structure_sql_schema_versions", force: :cascade do |t|
    t.text "content", null: false
    t.bigint "content_size", null: false
    t.datetime "created_at", null: false
    t.string "format_type", null: false
    t.integer "line_count", null: false
    t.string "pg_version", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_better_structure_sql_schema_versions_on_created_at", order: :desc
    t.check_constraint "format_type::text = ANY (ARRAY['sql'::character varying, 'rb'::character varying]::text[])", name: "format_type_check"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "parent_id"
    t.integer "position", default: 0
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_categories_on_lower_name"
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["position"], name: "index_categories_on_position"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "events", id: :uuid, default: -> { "uuid_generate_v8()" }, force: :cascade do |t|
    t.jsonb "event_data", default: {}
    t.string "event_name", null: false
    t.string "event_type", null: false
    t.inet "ip_address"
    t.datetime "occurred_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "user_agent"
    t.bigint "user_id"
    t.index ["event_data"], name: "index_events_on_event_data", using: :gin
    t.index ["event_name"], name: "index_events_on_event_name"
    t.index ["event_type"], name: "index_events_on_event_type"
    t.index ["occurred_at"], name: "index_events_on_occurred_at", using: :brin
    t.index ["user_id", "occurred_at"], name: "index_events_on_user_id_and_occurred_at"
    t.index ["user_id"], name: "index_events_on_user_id"
    t.check_constraint "length(event_type::text) > 0 AND length(event_name::text) > 0", name: "check_event_type_not_empty"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.jsonb "product_snapshot", default: {}
    t.integer "quantity", null: false
    t.decimal "subtotal", precision: 10, scale: 2, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "product_id"], name: "index_order_items_on_order_id_and_product_id", unique: true
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.check_constraint "unit_price > 0::numeric AND discount_amount >= 0::numeric AND subtotal >= 0::numeric", name: "check_item_amounts_positive"
  end

  create_table "orders", force: :cascade do |t|
    t.jsonb "billing_address", default: {}
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "delivered_at", precision: nil
    t.text "notes"
    t.string "order_number", null: false
    t.datetime "shipped_at", precision: nil
    t.jsonb "shipping_address", default: {}
    t.decimal "shipping_cost", precision: 10, scale: 2, default: "0.0", null: false
    t.enum "status", default: "draft", null: false, enum_type: "post_status"
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "tax_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["confirmed_at"], name: "index_orders_on_confirmed_at", where: "(confirmed_at IS NOT NULL)"
    t.index ["created_at"], name: "index_orders_created_at_brin", using: :brin
    t.index ["created_at"], name: "index_orders_on_created_at"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["shipped_at"], name: "index_orders_on_shipped_at", where: "(shipped_at IS NOT NULL)"
    t.index ["shipping_address"], name: "index_orders_shipping_address_path", opclass: :jsonb_path_ops, using: :gin
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.check_constraint "subtotal >= 0::numeric AND tax_amount >= 0::numeric AND shipping_cost >= 0::numeric AND total_amount >= 0::numeric", name: "check_order_amounts_positive"
  end

  create_table "posts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "published_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["published_at"], name: "index_posts_on_published_at", where: "(published_at IS NOT NULL)"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "product_price_history", force: :cascade do |t|
    t.datetime "changed_at", precision: nil, null: false
    t.decimal "new_price", precision: 10, scale: 2, null: false
    t.decimal "old_price", precision: 10, scale: 2
    t.bigint "product_id", null: false
    t.index ["product_id", "changed_at"], name: "index_product_price_history_on_product_id_and_changed_at"
    t.index ["product_id"], name: "index_product_price_history_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "discount_percentage", precision: 5, scale: 2
    t.boolean "is_active", default: true
    t.boolean "is_featured", default: false
    t.jsonb "metadata", default: {}
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "sku", null: false
    t.jsonb "specifications", default: {}
    t.integer "stock_quantity", default: 0, null: false
    t.string "tags", default: [], array: true
    t.datetime "updated_at", null: false
    t.index "((price * ((1)::numeric - (COALESCE(discount_percentage, (0)::numeric) / (100)::numeric))))", name: "index_products_on_discounted_price"
    t.index "to_tsvector('english'::regconfig, (((COALESCE(name, ''::character varying))::text || ' '::text) || COALESCE(description, ''::text)))", name: "index_products_fulltext_search", using: :gin
    t.index ["category_id", "is_active", "price"], name: "index_products_on_available_items", where: "((is_active = true) AND (stock_quantity > 0))"
    t.index ["category_id", "price"], name: "index_products_on_category_id_and_price"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["created_at"], name: "index_products_on_created_at"
    t.index ["is_active"], name: "index_products_on_is_active"
    t.index ["is_featured"], name: "index_products_on_is_featured", where: "(is_featured = true)"
    t.index ["metadata"], name: "index_products_metadata_path", opclass: :jsonb_path_ops, using: :gin
    t.index ["metadata"], name: "index_products_on_metadata", using: :gin
    t.index ["name"], name: "index_products_on_name"
    t.index ["price"], name: "index_products_on_price"
    t.index ["sku"], name: "index_active_products_unique_sku", unique: true, where: "(is_active = true)"
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["specifications"], name: "index_products_on_specifications", using: :gin
    t.index ["tags"], name: "index_products_on_tags", using: :gin
    t.check_constraint "discount_percentage >= 0::numeric AND discount_percentage <= 100::numeric", name: "check_discount_range"
    t.check_constraint "price > 0::numeric", name: "check_price_positive"
    t.check_constraint "stock_quantity >= 0", name: "check_stock_non_negative"
  end

  create_table "sessions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", precision: nil, null: false
    t.inet "ip_address"
    t.datetime "last_accessed_at", precision: nil
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_sessions_on_expires_at"
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "encrypted_password"
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "uuid_generate_v4()" }
    t.index "lower((email)::text)", name: "index_users_on_lower_email"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["uuid"], name: "index_users_on_uuid"
  end

  add_foreign_key "categories", "categories", column: "parent_id", on_delete: :cascade
  add_foreign_key "events", "users"
  add_foreign_key "order_items", "orders", on_delete: :cascade
  add_foreign_key "order_items", "products", on_delete: :restrict
  add_foreign_key "orders", "users", on_delete: :restrict
  add_foreign_key "posts", "users", on_delete: :cascade
  add_foreign_key "product_price_history", "products"
  add_foreign_key "products", "categories", on_delete: :restrict
  add_foreign_key "sessions", "users"
end
