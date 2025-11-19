# frozen_string_literal: true

class CreateSchemaVersions < ActiveRecord::Migration[8.1]
  def change
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
