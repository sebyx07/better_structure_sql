# frozen_string_literal: true

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

ActiveRecord::Schema[8.1].define(version: 20_250_101_000_003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'pg_catalog.plpgsql'
  enable_extension 'pgcrypto'
  enable_extension 'uuid-ossp'

  create_table 'better_structure_sql_schema_versions', force: :cascade do |t|
    t.text 'content', null: false
    t.datetime 'created_at', null: false
    t.string 'format_type', null: false
    t.string 'pg_version', null: false
    t.datetime 'updated_at', null: false
    t.index ['created_at'], name: 'index_better_structure_sql_schema_versions_on_created_at'
  end

  create_table 'posts', force: :cascade do |t|
    t.text 'body'
    t.datetime 'created_at', null: false
    t.datetime 'published_at'
    t.string 'title', null: false
    t.datetime 'updated_at', null: false
    t.bigint 'user_id', null: false
    t.index ['published_at'], name: 'index_posts_on_published_at', where: '(published_at IS NOT NULL)'
    t.index ['user_id'], name: 'index_posts_on_user_id'
  end

  create_table 'users', force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.string 'email', null: false
    t.string 'encrypted_password'
    t.datetime 'updated_at', null: false
    t.uuid 'uuid', default: -> { 'uuid_generate_v4()' }
    t.index ['email'], name: 'index_users_on_email', unique: true
    t.index ['uuid'], name: 'index_users_on_uuid'
  end

  add_foreign_key 'posts', 'users', on_delete: :cascade
end
