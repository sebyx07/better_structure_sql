# frozen_string_literal: true

# Exercises SQLite DDL the dumper must round-trip: AUTOINCREMENT, STRICT and
# WITHOUT ROWID tables, generated columns, collations, named and unnamed CHECK
# constraints, composite inline foreign keys, partial and expression indexes.
class CreateSqliteFeatureShowcase < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE TABLE regions (
        code TEXT NOT NULL,
        country TEXT NOT NULL,
        name TEXT COLLATE NOCASE,
        PRIMARY KEY (code, country)
      ) WITHOUT ROWID
    SQL
    execute <<~SQL
      CREATE TABLE ledger_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        region_code TEXT NOT NULL,
        region_country TEXT NOT NULL,
        amount INTEGER NOT NULL DEFAULT 0 CHECK (amount > -1000000),
        quantity INTEGER NOT NULL DEFAULT 1,
        total INTEGER GENERATED ALWAYS AS (amount * quantity) STORED,
        label TEXT AS (upper(region_code) || '-' || region_country) VIRTUAL,
        note TEXT DEFAULT 'it''s (here)',
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT chk_ledger_quantity CHECK (quantity BETWEEN 1 AND (10 * 100)),
        CONSTRAINT fk_ledger_region FOREIGN KEY (region_code, region_country)
          REFERENCES regions (code, country) ON DELETE CASCADE
      )
    SQL
    execute 'CREATE TABLE settings (key TEXT PRIMARY KEY, value ANY, version INTEGER NOT NULL) STRICT'
    execute 'CREATE INDEX idx_ledger_positive ON ledger_entries (region_code) WHERE amount > 0'
    execute 'CREATE UNIQUE INDEX idx_ledger_lower_note ON ledger_entries (lower(note), quantity DESC)'
  end

  def down
    drop_table :settings
    drop_table :ledger_entries
    drop_table :regions
  end
end
