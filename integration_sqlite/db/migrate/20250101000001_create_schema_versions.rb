# frozen_string_literal: true

class CreateSchemaVersions < ActiveRecord::Migration[8.1]
  def change
    # Configure SQLite PRAGMAs for optimal behavior
    # Only set these if using SQLite adapter
    # Note: Some PRAGMAs can't be set inside a transaction, so we skip those
    if connection.adapter_name == 'SQLite'
      execute 'PRAGMA foreign_keys = ON;'
      execute 'PRAGMA busy_timeout = 5000;'
      execute 'PRAGMA cache_size = -20000;' # 20MB cache (negative = KB)
      execute 'PRAGMA temp_store = MEMORY;'
    end

    create_table :better_structure_sql_schema_versions do |t|
      t.text :content, null: false
      t.string :sqlite_version
      t.string :format_type, default: 'sql'
      t.binary :zip_archive
      t.string :output_mode, default: 'single_file'

      t.timestamps
    end

    add_index :better_structure_sql_schema_versions, :created_at
  end
end
