# frozen_string_literal: true

class CreateBetterStructureSqlSchemaVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :better_structure_sql_schema_versions do |t|
      t.text :content, null: false
      t.string :pg_version, null: false
      t.string :format_type, null: false

      t.timestamps
    end

    add_index :better_structure_sql_schema_versions, :created_at
  end
end
