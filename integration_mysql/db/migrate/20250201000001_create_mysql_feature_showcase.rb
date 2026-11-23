# frozen_string_literal: true

# Exercises MySQL DDL the dumper must round-trip: unsigned/AUTO_INCREMENT keys,
# ENUM/SET, generated columns, expression and ON UPDATE defaults, column
# charsets/collations, prefix/descending/functional/FULLTEXT indexes, composite
# foreign keys, CHECK constraints, views WITH CHECK OPTION, a view reading a
# later-named view, ordered triggers and routines with nested BEGIN/END blocks.
class CreateMysqlFeatureShowcase < ActiveRecord::Migration[8.1]
  def up
    create_accounts
    create_entries
    create_routines_and_triggers
    execute <<~SQL
      CREATE VIEW active_accounts AS
      SELECT id, code, 'x;y' AS label FROM accounts WHERE status = 'active'
      WITH CASCADED CHECK OPTION
    SQL
    # Sorts before the view it reads, so name order alone cannot load it
    execute 'CREATE VIEW a_active_account_codes AS SELECT code FROM active_accounts'
  end

  def down
    execute 'DROP VIEW IF EXISTS a_active_account_codes'
    execute 'DROP VIEW IF EXISTS active_accounts'
    execute 'DROP FUNCTION IF EXISTS add_one'
    execute 'DROP PROCEDURE IF EXISTS bump_quantity'
    drop_table :entries
    drop_table :accounts
  end

  private

  def mariadb?
    connection.mariadb?
  end

  def create_accounts
    execute <<~SQL
      CREATE TABLE accounts (
        id int unsigned NOT NULL AUTO_INCREMENT,
        region char(2) NOT NULL,
        code varchar(20) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL,
        status enum('active','it''s','closed') NOT NULL DEFAULT 'active',
        flags set('a','b','c') DEFAULT 'a,b',
        price decimal(10,2) NOT NULL DEFAULT '0.00',
        quantity smallint unsigned NOT NULL DEFAULT 1,
        total decimal(12,2) GENERATED ALWAYS AS (price * quantity) STORED,
        label varchar(50) GENERATED ALWAYS AS (concat(region, '-', code)) VIRTUAL,
        active tinyint(1) NOT NULL DEFAULT 1,
        bits bit(3) DEFAULT b'101',
        token varchar(36) DEFAULT (uuid()),
        note varchar(100) DEFAULT 'paren(s) & ''quotes'' \\\\ backslash',
        `key` varchar(10),
        bio text,
        created_at datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
        updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        UNIQUE KEY uq_accounts_region_code (region, code),
        KEY idx_accounts_note_prefix (note(10)),
        KEY idx_accounts_price_desc (price DESC, quantity),
        #{'KEY idx_accounts_lower_note ((lower(note))),' unless mariadb?}
        FULLTEXT KEY ft_accounts_bio (bio),
        CONSTRAINT chk_accounts_price CHECK (price >= 0),
        CONSTRAINT chk_accounts_note CHECK (note <> 'x''y')
      )
    SQL
  end

  def create_entries
    execute <<~SQL
      CREATE TABLE entries (
        id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
        region char(2) NOT NULL,
        code varchar(20) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL,
        account_id int unsigned,
        CONSTRAINT fk_entries_account FOREIGN KEY (account_id) REFERENCES accounts (id)
          ON DELETE SET NULL ON UPDATE CASCADE,
        CONSTRAINT fk_entries_region_code FOREIGN KEY (region, code) REFERENCES accounts (region, code)
          ON DELETE CASCADE
      )
    SQL
  end

  def create_routines_and_triggers
    execute <<~SQL
      CREATE TRIGGER accounts_default_quantity BEFORE INSERT ON accounts FOR EACH ROW
      BEGIN
        IF NEW.quantity = 0 THEN
          SET NEW.quantity = 1;
        END IF;
      END
    SQL
    execute <<~SQL
      CREATE TRIGGER accounts_default_note BEFORE INSERT ON accounts FOR EACH ROW
      FOLLOWS accounts_default_quantity
      SET NEW.note = coalesce(NEW.note, 'n')
    SQL
    execute <<~SQL
      CREATE PROCEDURE bump_quantity(IN account INT)
      BEGIN
        DECLARE done INT DEFAULT 0;
        BEGIN
          UPDATE accounts SET quantity = quantity + 1 WHERE id = account;
        END;
        IF done = 0 THEN
          SELECT 1;
        END IF;
      END
    SQL
    execute 'CREATE FUNCTION add_one(x INT) RETURNS int DETERMINISTIC RETURN x + 1'
  end
end
