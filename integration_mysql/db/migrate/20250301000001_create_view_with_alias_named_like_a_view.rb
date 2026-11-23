# frozen_string_literal: true

# On MariaDB the dump finds the views a view reads in its definition. b_codes
# names a column c_codes and sorts first, while c_codes reads b_codes: the dump
# must still create b_codes first.
class CreateViewWithAliasNamedLikeAView < ActiveRecord::Migration[8.1]
  def up
    execute 'CREATE VIEW b_codes AS SELECT code, id AS c_codes FROM accounts'
    execute 'CREATE VIEW c_codes AS SELECT code FROM b_codes'
  end

  def down
    execute 'DROP VIEW IF EXISTS c_codes'
    execute 'DROP VIEW IF EXISTS b_codes'
  end
end
