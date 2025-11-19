# frozen_string_literal: true

class CreateUuidExamples < ActiveRecord::Migration[8.1]
  def up
    # Create custom UUID v8 function (timestamp-based sortable UUID)
    execute <<~SQL
      CREATE FUNCTION public.uuid_generate_v8()
      RETURNS uuid
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
    SQL

    # Table using UUID v4 (from uuid-ossp extension)
    create_table :sessions, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.references :user, type: :bigint, null: false, foreign_key: true
      t.string :token, null: false
      t.inet :ip_address
      t.string :user_agent
      t.timestamp :expires_at, null: false
      t.timestamp :last_accessed_at
      t.timestamps
    end

    add_index :sessions, :token, unique: true
    add_index :sessions, :expires_at

    # Table using custom UUID v8 (sortable by timestamp)
    create_table :events, id: :uuid, default: -> { 'uuid_generate_v8()' } do |t|
      t.references :user, type: :bigint, foreign_key: true
      t.string :event_type, null: false
      t.string :event_name, null: false
      t.jsonb :event_data, default: {}
      t.inet :ip_address
      t.string :user_agent
      t.timestamp :occurred_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :events, :event_type
    add_index :events, :event_name
    add_index :events, [:user_id, :occurred_at]
    add_index :events, :event_data, using: :gin
    add_index :events, :occurred_at, using: :brin

    # Add check constraint
    execute <<~SQL
      ALTER TABLE events
        ADD CONSTRAINT check_event_type_not_empty
        CHECK (length(event_type) > 0 AND length(event_name) > 0);
    SQL
  end

  def down
    drop_table :events
    drop_table :sessions
    execute 'DROP FUNCTION IF EXISTS public.uuid_generate_v8();'
  end
end
