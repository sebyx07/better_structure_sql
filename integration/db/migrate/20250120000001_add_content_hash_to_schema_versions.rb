# frozen_string_literal: true

require 'digest'

class AddContentHashToSchemaVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :better_structure_sql_schema_versions, :content_hash, :string, limit: 32
    add_index :better_structure_sql_schema_versions, :content_hash

    reversible do |dir|
      dir.up do
        # Backfill existing records with calculated MD5 hashes
        BetterStructureSql::SchemaVersion.find_each do |version|
          hash = Digest::MD5.hexdigest(version.content)
          version.update_column(:content_hash, hash)
        end
      end
    end

    # Make NOT NULL after backfill
    change_column_null :better_structure_sql_schema_versions, :content_hash, false
  end
end
