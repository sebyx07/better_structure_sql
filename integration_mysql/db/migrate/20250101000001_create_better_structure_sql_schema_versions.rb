# frozen_string_literal: true

class CreateBetterStructureSqlSchemaVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :better_structure_sql_schema_versions do |t|
      t.text :content, null: false
      t.binary :zip_archive, null: true, limit: 16.megabytes
      t.string :pg_version, null: false
      t.string :format_type, null: false
      t.string :output_mode, null: false
      t.bigint :content_size, null: false
      t.integer :line_count, null: false
      t.integer :file_count, null: true

      t.timestamps
    end

    add_index :better_structure_sql_schema_versions, :created_at, order: { created_at: :desc }
    add_index :better_structure_sql_schema_versions, :output_mode
  end
end
