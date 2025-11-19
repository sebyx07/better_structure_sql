# frozen_string_literal: true

class CreateLargeTestSchema < ActiveRecord::Migration[7.0]
  def up
    Rails.logger.debug 'Generating large schema to demonstrate multi-file feature...'

    # Generate 50 tables with realistic structure
    50.times do |i|
      table_name = "large_table_#{i.to_s.rjust(3, '0')}"

      create_table table_name do |t|
        t.string :name, null: false
        t.text :description
        t.integer :status, default: 0
        t.decimal :price, precision: 10, scale: 2
        t.boolean :active, default: true
        t.jsonb :metadata, default: {}
        t.inet :ip_address
        t.uuid :external_id
        t.timestamps
      end

      # Add 3 indexes per table
      add_index table_name, :name
      add_index table_name, :status
      add_index table_name, %i[active status], name: "idx_#{table_name}_active_status"

      # Add check constraints
      execute <<~SQL
        ALTER TABLE #{table_name}
        ADD CONSTRAINT chk_#{table_name}_status
        CHECK (status >= 0 AND status <= 10);
      SQL
    end

    # Generate foreign keys between tables
    25.times do |i|
      source_table = "large_table_#{(i * 2).to_s.rjust(3, '0')}"
      target_table = "large_table_#{((i * 2) + 1).to_s.rjust(3, '0')}"

      add_column source_table, :related_id, :bigint
      add_foreign_key source_table, target_table, column: :related_id
    end

    # Generate 20 views
    20.times do |i|
      view_name = "large_view_#{i.to_s.rjust(2, '0')}"
      table_name = "large_table_#{(i * 2).to_s.rjust(3, '0')}"

      execute <<~SQL
        CREATE VIEW #{view_name} AS
        SELECT id, name, status, active, created_at
        FROM #{table_name}
        WHERE active = true;
      SQL
    end

    # Generate 10 functions
    10.times do |i|
      function_name = "calculate_total_#{i}"

      execute <<~SQL
        CREATE OR REPLACE FUNCTION #{function_name}(base_amount numeric)
        RETURNS numeric AS $$
        BEGIN
          -- Complex calculation to make function multi-line
          RETURN base_amount * 1.#{i} + #{i * 10};
        END;
        $$ LANGUAGE plpgsql IMMUTABLE;
      SQL
    end

    # Generate 15 triggers
    15.times do |i|
      table_name = "large_table_#{i.to_s.rjust(3, '0')}"
      trigger_name = "trg_#{table_name}_update_timestamp"

      # First create the trigger function
      execute <<~SQL
        CREATE OR REPLACE FUNCTION update_timestamp_#{i}()
        RETURNS trigger AS $$
        BEGIN
          NEW.updated_at = CURRENT_TIMESTAMP;
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      SQL

      # Then create the trigger
      execute <<~SQL
        CREATE TRIGGER #{trigger_name}
        BEFORE UPDATE ON #{table_name}
        FOR EACH ROW
        EXECUTE FUNCTION update_timestamp_#{i}();
      SQL
    end

    Rails.logger.debug '✓ Large schema generated successfully!'
    Rails.logger.debug ''
    Rails.logger.debug 'Statistics:'
    Rails.logger.debug '  - 50 tables (each with ~10 columns)'
    Rails.logger.debug '  - 150 indexes (3 per table)'
    Rails.logger.debug '  - 50 check constraints'
    Rails.logger.debug '  - 25 foreign keys'
    Rails.logger.debug '  - 20 views'
    Rails.logger.debug '  - 10 functions'
    Rails.logger.debug '  - 15 triggers'
    Rails.logger.debug ''
    Rails.logger.debug 'Total database objects: ~270'
    Rails.logger.debug 'Expected structure.sql size: ~3,000-5,000 lines'
  end

  def down
    # Drop in reverse order
    15.times do |i|
      execute "DROP FUNCTION IF EXISTS update_timestamp_#{i}() CASCADE"
    end

    10.times do |i|
      execute "DROP FUNCTION IF EXISTS calculate_total_#{i}()"
    end

    20.times do |i|
      execute "DROP VIEW IF EXISTS large_view_#{i.to_s.rjust(2, '0')}"
    end

    50.times do |i|
      drop_table "large_table_#{i.to_s.rjust(3, '0')}" if table_exists?("large_table_#{i.to_s.rjust(3, '0')}")
    end
  end
end
