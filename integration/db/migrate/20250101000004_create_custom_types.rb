# frozen_string_literal: true

class CreateCustomTypes < ActiveRecord::Migration[8.1]
  def up
    # Create enum types
    execute <<~SQL
      CREATE TYPE post_status AS ENUM ('draft', 'published', 'archived');
      CREATE TYPE user_role AS ENUM ('admin', 'moderator', 'user', 'guest');
      CREATE TYPE priority_level AS ENUM ('low', 'medium', 'high', 'urgent');
    SQL

    # Create composite type
    execute <<~SQL
      CREATE TYPE address AS (
        street varchar(255),
        city varchar(100),
        state varchar(2),
        zip_code varchar(10),
        country varchar(50)
      );
    SQL

    # Create domain type with constraint
    execute <<~SQL
      CREATE DOMAIN email_address AS varchar(255)
        CHECK (VALUE ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Z|a-z]{2,}$');

      CREATE DOMAIN positive_integer AS integer
        CHECK (VALUE > 0);

      CREATE DOMAIN percentage AS numeric(5,2)
        CHECK (VALUE >= 0 AND VALUE <= 100);
    SQL
  end

  def down
    execute 'DROP DOMAIN IF EXISTS percentage CASCADE;'
    execute 'DROP DOMAIN IF EXISTS positive_integer CASCADE;'
    execute 'DROP DOMAIN IF EXISTS email_address CASCADE;'
    execute 'DROP TYPE IF EXISTS address CASCADE;'
    execute 'DROP TYPE IF EXISTS priority_level CASCADE;'
    execute 'DROP TYPE IF EXISTS user_role CASCADE;'
    execute 'DROP TYPE IF EXISTS post_status CASCADE;'
  end
end
