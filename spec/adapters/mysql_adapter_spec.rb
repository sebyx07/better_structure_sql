# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/better_structure_sql/adapters/mysql_adapter'

RSpec.describe BetterStructureSql::Adapters::MysqlAdapter do
  let(:connection) { double('ActiveRecord::Connection') }
  let(:adapter)    { described_class.new(connection) }

  describe '#fetch_extensions' do
    it 'returns empty array (MySQL does not support extensions)' do
      expect(adapter.fetch_extensions(connection)).to eq([])
    end
  end

  describe '#fetch_custom_types' do
    it 'returns empty array (MySQL does not have custom types like PostgreSQL)' do
      expect(adapter.fetch_custom_types(connection)).to eq([])
    end
  end

  # Stub the server version and route each query to canned rows
  def stub_server(version = '8.0.35')
    allow(connection).to receive(:select_value).with('SELECT VERSION()').and_return(version)
  end

  def stub_rows(pattern, rows)
    allow(connection).to receive(:select_rows).with(pattern).and_return(rows)
  end

  def column_row(name, column_type, default: nil, extra: '', collation: nil)
    {
      'TABLE_NAME' => 'accounts', 'COLUMN_NAME' => name, 'DATA_TYPE' => column_type[/\A\w+/],
      'COLUMN_TYPE' => column_type, 'IS_NULLABLE' => 'YES', 'COLUMN_DEFAULT' => default, 'EXTRA' => extra,
      'CHARACTER_SET_NAME' => collation && collation[/\A[^_]+/], 'COLLATION_NAME' => collation,
      'CHARACTER_MAXIMUM_LENGTH' => nil, 'NUMERIC_PRECISION' => nil, 'NUMERIC_SCALE' => nil
    }
  end

  describe '#fetch_tables' do
    let(:columns) { [] }
    let(:checks) { [] }
    let(:tables) { adapter.fetch_tables(connection) }

    def column(name)
      tables.first[:columns].find { |col| col[:name] == name }
    end

    before do
      stub_rows(/FROM information_schema.TABLES/, [%w[accounts app InnoDB utf8mb4_unicode_ci]])
      allow(connection).to receive(:select_all).with(/FROM information_schema.COLUMNS/).and_return(columns)
      stub_rows(/CONSTRAINT_NAME = 'PRIMARY'/, [%w[accounts id]])
      stub_rows(/CHECK_CONSTRAINTS/, checks)
    end

    context 'with MySQL' do
      let(:columns) do
        [
          column_row('id', 'int unsigned', extra: 'auto_increment'),
          column_row('code', 'varchar(20)', default: "it's \\ here", collation: 'latin1_bin'),
          column_row('status', "enum('a','b')", default: 'a'),
          column_row('price', 'decimal(10,2)', default: '0.00'),
          column_row('bits', 'bit(3)', default: "b'101'"),
          column_row('token', 'varchar(36)', default: "concat(_utf8mb4\\'a\\',uuid())", extra: 'DEFAULT_GENERATED'),
          column_row('created_at', 'datetime(6)', default: 'CURRENT_TIMESTAMP(6)',
                                                  extra: 'DEFAULT_GENERATED on update CURRENT_TIMESTAMP(6)'),
          column_row('total', 'decimal(12,2)', extra: 'STORED GENERATED')
        ]
      end
      let(:checks) { [['accounts', 'chk_code', "(`code` <> _utf8mb4\\'x\\\\\\'y\\')", 'YES'], ['accounts', 'chk_price', '(`price` >= 0)', 'NO']] }

      before do
        stub_server
        stub_rows('SHOW CREATE TABLE `accounts`', [['accounts', <<~SQL]])
          CREATE TABLE `accounts` (
            `total` decimal(12,2) GENERATED ALWAYS AS ((`price` * 2)) STORED,
            PRIMARY KEY (`id`)
          ) ENGINE=InnoDB
        SQL
      end

      it 'returns table options and the full COLUMN_TYPE (unsigned, precision, enum values)' do
        expect(tables.first).to include(name: 'accounts', engine: 'InnoDB', collation: 'utf8mb4_unicode_ci', primary_key: ['id'])
        expect(tables.first[:columns].pluck(:type))
          .to eq(['int unsigned', 'varchar(20)', "enum('a','b')", 'decimal(10,2)', 'bit(3)', 'varchar(36)', 'datetime(6)', 'decimal(12,2)'])
      end

      it 'returns defaults as SQL: quoted literals, bare numbers and bit values, parenthesized expressions' do
        expect(tables.first[:columns].pluck(:default))
          .to eq([nil, "'it''s \\\\ here'", "'a'", '0.00', "b'101'", "(concat(_utf8mb4'a',uuid()))", 'CURRENT_TIMESTAMP(6)', nil])
      end

      it 'flags AUTO_INCREMENT and ON UPDATE' do
        expect(column('id')).to include(auto_increment: true, on_update: nil)
        expect(column('created_at')).to include(auto_increment: false, on_update: 'CURRENT_TIMESTAMP(6)')
      end

      it 'returns column charset and collation' do
        expect(column('code')).to include(charset: 'latin1', collation: 'latin1_bin')
      end

      it 'takes generation expressions from SHOW CREATE TABLE' do
        expect(column('total')[:generated]).to eq(expression: '(`price` * 2)', kind: 'STORED')
      end

      it 'returns complete CHECK clauses, unescaped, with NOT ENFORCED' do
        expect(tables.first[:constraints]).to eq(
          [
            { name: 'chk_code', definition: "CHECK ((`code` <> _utf8mb4'x\\'y'))", type: :check },
            { name: 'chk_price', definition: 'CHECK ((`price` >= 0)) NOT ENFORCED', type: :check }
          ]
        )
      end

      it 'reads CHECK constraints through TABLE_CONSTRAINTS (MySQL has no CHECK_CONSTRAINTS.TABLE_NAME)' do
        tables
        expect(connection).to have_received(:select_rows).with(/JOIN information_schema.CHECK_CONSTRAINTS/)
      end
    end

    context 'with MariaDB' do
      let(:columns) do
        [
          column_row('status', 'varchar(10)', default: "'it''s'"),
          column_row('note', 'varchar(10)', default: 'NULL'),
          column_row('created_at', 'timestamp', default: 'current_timestamp()', extra: 'on update current_timestamp()'),
          column_row('metadata', 'longtext', default: 'NULL', collation: 'utf8mb4_bin')
        ]
      end
      let(:checks) do
        [['accounts', 'metadata', 'json_valid(`metadata`)', 'YES'], ['accounts', 'chk_note', "`note` <> 'a\\'b'", 'YES']]
      end

      before { stub_server('11.4.2-MariaDB-ubu2404') }

      it 'uses the stored SQL defaults, treating the string NULL as no default' do
        expect(tables.first[:columns].pluck(:default)).to eq(["'it''s'", nil, 'current_timestamp()', nil])
        expect(column('created_at')[:on_update]).to eq('current_timestamp()')
      end

      it 'dumps LONGTEXT columns guarded by json_valid as JSON and keeps other checks verbatim' do
        expect(column('metadata')).to include(type: 'json', charset: nil, collation: nil)
        expect(tables.first[:constraints]).to eq([{ name: 'chk_note', definition: "CHECK (`note` <> 'a\\'b')", type: :check }])
      end
    end
  end

  describe '#fetch_indexes' do
    it 'builds complete definitions for prefix, descending, functional, fulltext and invisible indexes' do
      stub_server('8.0.35')
      stub_rows(/FROM information_schema.STATISTICS/, [
        ['accounts', 'ft_bio', 'bio', 1, 'FULLTEXT', nil, nil, nil, 'YES'],
        ['accounts', 'idx_desc', 'price', 1, 'BTREE', nil, 'D', nil, 'YES'],
        ['accounts', 'idx_desc', 'qty', 1, 'BTREE', nil, 'A', nil, 'YES'],
        ['accounts', 'idx_lower', nil, 1, 'BTREE', nil, 'A', 'lower(`note`)', 'NO'],
        ['accounts', 'uq_note', 'note', 0, 'BTREE', 10, 'A', nil, 'YES']
      ])

      expect(adapter.fetch_indexes(connection).to_h { |index| [index[:name], index[:definition]] }).to eq(
        'ft_bio' => 'CREATE FULLTEXT INDEX `ft_bio` ON `accounts` (`bio`)',
        'idx_desc' => 'CREATE INDEX `idx_desc` ON `accounts` (`price` DESC, `qty`)',
        'idx_lower' => 'CREATE INDEX `idx_lower` ON `accounts` ((lower(`note`))) INVISIBLE',
        'uq_note' => 'CREATE UNIQUE INDEX `uq_note` ON `accounts` (`note`(10))'
      )
    end

    it 'does not select EXPRESSION or IS_VISIBLE on servers without them' do
      stub_server('11.4.2-MariaDB')
      stub_rows(/NULL AS EXPRESSION, 'YES' AS IS_VISIBLE/, [['users', 'idx_email', 'email', 0, 'BTREE', nil, 'A', nil, 'YES']])

      expect(adapter.fetch_indexes(connection).first)
        .to include(name: 'idx_email', columns: ['email'], unique: true,
                    definition: 'CREATE UNIQUE INDEX `idx_email` ON `users` (`email`)')
    end
  end

  describe '#fetch_foreign_keys' do
    it 'groups composite foreign keys into one entry in key order' do
      stub_rows(/FROM information_schema.KEY_COLUMN_USAGE/, [
        ['entries', 'fk_account', 'account_id', 'accounts', 'id', 'CASCADE', 'SET NULL'],
        ['entries', 'fk_region', 'region', 'accounts', 'region', 'NO ACTION', 'CASCADE'],
        ['entries', 'fk_region', 'code', 'accounts', 'code', 'NO ACTION', 'CASCADE']
      ])

      expect(adapter.fetch_foreign_keys(connection)).to eq(
        [
          { table: 'entries', name: 'fk_account', columns: ['account_id'], foreign_table: 'accounts', foreign_columns: ['id'],
            on_update: 'CASCADE', on_delete: 'SET NULL' },
          { table: 'entries', name: 'fk_region', columns: %w[region code], foreign_table: 'accounts',
            foreign_columns: %w[region code], on_update: 'NO ACTION', on_delete: 'CASCADE' }
        ]
      )
    end
  end

  describe '#fetch_views' do
    it 'takes the query from SHOW CREATE VIEW, which does not qualify tables with the database name' do
      stub_server
      stub_rows(/VIEW_TABLE_USAGE/, [])
      stub_rows(/FROM information_schema.VIEWS/, [%w[active_users CASCADED YES]])
      stub_rows('SHOW CREATE VIEW `active_users`', [
        [
          'active_users',
          'CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `active_users` AS ' \
          "select `users`.`id` AS `id` from `users` where (`users`.`name` = 'a AS b') WITH CASCADED CHECK OPTION",
          'utf8mb4', 'utf8mb4_unicode_ci'
        ]
      ])

      expect(adapter.fetch_views(connection)).to eq(
        [
          { schema: 'public', name: 'active_users', check_option: 'CASCADED', updatable: true,
            definition: "select `users`.`id` AS `id` from `users` where (`users`.`name` = 'a AS b') WITH CASCADED CHECK OPTION" }
        ]
      )
    end
  end

  describe '#fetch_views ordering' do
    def stub_view(name, select)
      stub_rows("SHOW CREATE VIEW `#{name}`", [[name, "CREATE VIEW `#{name}` AS #{select}", 'utf8mb4', 'utf8mb4_unicode_ci']])
    end

    before do
      stub_rows(/FROM information_schema.VIEWS/, [%w[a_top NONE YES], %w[m_middle NONE YES], %w[z_base NONE YES]])
      stub_view('a_top', 'select `m_middle`.`id` AS `id` from `m_middle`')
      stub_view('m_middle', 'select `z_base`.`id` AS `id` from `z_base`')
      stub_view('z_base', 'select `users`.`id` AS `id` from `users`')
    end

    it 'creates each view after the views it reads, from VIEW_TABLE_USAGE on MySQL 8.0.13+' do
      stub_server('8.4.3')
      stub_rows(/VIEW_TABLE_USAGE/, [%w[a_top m_middle], %w[m_middle z_base], %w[z_base users]])

      expect(adapter.fetch_views(connection).pluck(:name)).to eq(%w[z_base m_middle a_top])
    end

    it 'finds the views a view reads in its definition on MariaDB, which has no VIEW_TABLE_USAGE' do
      stub_server('10.11.6-MariaDB')

      expect(adapter.fetch_views(connection).pluck(:name)).to eq(%w[z_base m_middle a_top])
    end

    it 'ignores a column alias, table alias or qualifier named like another view on MariaDB' do
      stub_server('11.4.2-MariaDB')
      stub_rows(/FROM information_schema.VIEWS/, [%w[a NONE YES], %w[b NONE YES]])
      # Output of MariaDB 11 for: a reads users and names a column b; b reads a
      stub_view('a', 'select `u`.`id` AS `id`,`u`.`name` AS `b` from `users` `u`')
      stub_view('b', 'select `x`.`id` AS `id` from (`a` `x` join `users` on(`users`.`id` = `x`.`id`))')

      expect(adapter.fetch_views(connection).pluck(:name)).to eq(%w[a b])
    end

    it 'finds views read in joins and subqueries on MariaDB' do
      stub_server('11.4.2-MariaDB')
      stub_view('a_top', 'select `users`.`id` AS `id` from ((`users` join `orders` on(`users`.`id` = `orders`.`id`)) ' \
                         'left join (select `m_middle`.`id` AS `id` from `m_middle`) `s` on(`s`.`id` = `users`.`id`)) ' \
                         'where exists(select 1 from `z_base` limit 1)')

      expect(adapter.fetch_views(connection).pluck(:name)).to eq(%w[z_base m_middle a_top])
    end
  end

  describe '#fetch_materialized_views' do
    it 'returns empty array (MySQL does not support materialized views)' do
      expect(adapter.fetch_materialized_views(connection)).to eq([])
    end
  end

  describe '#fetch_functions' do
    it 'fetches routines using SHOW CREATE' do
      stub_rows(/FROM information_schema.ROUTINES/, [%w[add_one FUNCTION], %w[bump PROCEDURE]])
      stub_rows('SHOW CREATE FUNCTION `add_one`', [['add_one', 'STRICT_TRANS_TABLES', 'CREATE FUNCTION `add_one`(x INT) RETURNS int RETURN x + 1']])
      stub_rows('SHOW CREATE PROCEDURE `bump`', [['bump', 'STRICT_TRANS_TABLES', "CREATE DEFINER=`root`@`%` PROCEDURE `bump`()\nBEGIN\n  SELECT 1;\nEND"]])

      expect(adapter.fetch_functions(connection)).to eq(
        [
          { schema: 'public', name: 'add_one', definition: 'CREATE FUNCTION `add_one`(x INT) RETURNS int RETURN x + 1' },
          { schema: 'public', name: 'bump', definition: "CREATE DEFINER=`root`@`%` PROCEDURE `bump`()\nBEGIN\n  SELECT 1;\nEND" }
        ]
      )
    end

    it 'raises when SHOW CREATE hides the definition (missing privileges)' do
      stub_rows(/FROM information_schema.ROUTINES/, [%w[secret PROCEDURE]])
      stub_rows('SHOW CREATE PROCEDURE `secret`', [['secret', 'STRICT_TRANS_TABLES', nil]])

      expect { adapter.fetch_functions(connection) }.to raise_error(BetterStructureSql::Error, /privileges/)
    end
  end

  describe '#fetch_sequences' do
    it 'returns empty array (MySQL uses AUTO_INCREMENT)' do
      expect(adapter.fetch_sequences(connection)).to eq([])
    end
  end

  describe '#fetch_triggers' do
    it 'returns triggers in firing order with their SHOW CREATE statement' do
      stub_rows(/ORDER BY EVENT_OBJECT_TABLE, ACTION_TIMING, EVENT_MANIPULATION, ACTION_ORDER/,
                [%w[z_first INSERT users BEFORE], %w[a_second INSERT users BEFORE]])
      stub_rows('SHOW CREATE TRIGGER `z_first`', [['z_first', 'STRICT_TRANS_TABLES', 'CREATE TRIGGER `z_first` BEFORE INSERT ON `users` FOR EACH ROW SET NEW.a = 1']])
      stub_rows('SHOW CREATE TRIGGER `a_second`', [['a_second', 'STRICT_TRANS_TABLES', 'CREATE TRIGGER `a_second` BEFORE INSERT ON `users` FOR EACH ROW SET NEW.b = 1']])

      expect(adapter.fetch_triggers(connection).map { |trigger| trigger.values_at(:name, :table, :event, :timing) })
        .to eq([%w[z_first users INSERT BEFORE], %w[a_second users INSERT BEFORE]])
      expect(adapter.fetch_triggers(connection).first[:definition]).to eq('CREATE TRIGGER `z_first` BEFORE INSERT ON `users` FOR EACH ROW SET NEW.a = 1')
    end
  end

  describe '#fetch_comments' do
    it 'returns table and column comments keyed by name' do
      stub_rows(/TABLE_COMMENT/, [['users', 'User accounts']])
      stub_rows(/COLUMN_COMMENT/, [%w[users email Login]])

      expect(adapter.fetch_comments(connection))
        .to eq(tables: { 'users' => 'User accounts' }, columns: { %w[users email] => 'Login' },
               indexes: {}, views: {}, functions: {}, procedures: {})
    end
  end

  describe 'capability methods' do
    it 'returns false for PostgreSQL-specific features' do
      expect(adapter.supports_extensions?).to be false
      expect(adapter.supports_materialized_views?).to be false
      expect(adapter.supports_custom_types?).to be false
      expect(adapter.supports_domains?).to be false
      expect(adapter.supports_sequences?).to be false
    end

    it 'returns true for supported features' do
      expect(adapter.supports_functions?).to be true
      expect(adapter.supports_triggers?).to be true
    end

    it 'supports check constraints for MySQL 8.0.16+' do
      allow(connection).to receive(:select_value).and_return('8.0.35')

      expect(adapter.supports_check_constraints?).to be true
    end

    it 'supports check constraints for MariaDB 10.2+' do
      allow(connection).to receive(:select_value).and_return('10.6.18-MariaDB')

      expect(adapter.supports_check_constraints?).to be true
    end

    it 'does not support check constraints for MySQL < 8.0.16' do
      allow(connection).to receive(:select_value).and_return('5.7.44')

      expect(adapter.supports_check_constraints?).to be false
    end
  end

  describe '#database_version' do
    it 'detects MySQL version' do
      allow(connection).to receive(:select_value).and_return('8.0.35-log')

      expect(adapter.database_version).to eq('8.0.35')
    end
  end

  describe '#parse_version' do
    it 'parses MySQL version string' do
      expect(adapter.parse_version('8.0.35')).to eq('8.0.35')
      expect(adapter.parse_version('5.7.44-log')).to eq('5.7.44')
    end

    it 'returns unknown for invalid version' do
      expect(adapter.parse_version('invalid')).to eq('unknown')
    end
  end
end
