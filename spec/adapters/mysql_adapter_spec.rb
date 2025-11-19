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

  describe '#fetch_tables' do
    it 'fetches tables using information_schema' do
      query_result = [
        %w[users public],
        %w[posts public]
      ]

      allow(connection).to receive(:execute).and_return(query_result)
      allow(connection).to receive(:quote).and_return("'users'", "'posts'")
      allow(adapter).to receive_messages(fetch_columns: [], fetch_primary_key: [], fetch_constraints: [])

      tables = adapter.fetch_tables(connection)

      expect(tables.length).to eq(2)
      expect(tables.first[:name]).to eq('users')
      expect(tables.last[:name]).to eq('posts')
    end
  end

  describe '#fetch_indexes' do
    it 'fetches indexes and groups multi-column indexes' do
      query_result = [
        ['users', 'idx_email', 'email', 1, 0, 'BTREE'],
        ['posts', 'idx_user_status', 'user_id', 1, 1, 'BTREE'],
        ['posts', 'idx_user_status', 'status', 2, 1, 'BTREE']
      ]

      allow(connection).to receive(:execute).and_return(query_result)

      indexes = adapter.fetch_indexes(connection)

      expect(indexes.length).to eq(2)
      expect(indexes.first[:name]).to eq('idx_email')
      expect(indexes.first[:columns]).to eq(['email'])
      expect(indexes.first[:unique]).to be true

      expect(indexes.last[:name]).to eq('idx_user_status')
      expect(indexes.last[:columns]).to eq(%w[user_id status])
      expect(indexes.last[:unique]).to be false
    end
  end

  describe '#fetch_foreign_keys' do
    it 'fetches foreign keys using information_schema' do
      query_result = [
        %w[posts fk_posts_user user_id users id CASCADE CASCADE]
      ]

      allow(connection).to receive(:execute).and_return(query_result)

      foreign_keys = adapter.fetch_foreign_keys(connection)

      expect(foreign_keys.length).to eq(1)
      expect(foreign_keys.first[:table]).to eq('posts')
      expect(foreign_keys.first[:name]).to eq('fk_posts_user')
      expect(foreign_keys.first[:column]).to eq('user_id')
      expect(foreign_keys.first[:foreign_table]).to eq('users')
      expect(foreign_keys.first[:on_delete]).to eq('CASCADE')
    end
  end

  describe '#fetch_views' do
    it 'fetches views using information_schema' do
      query_result = [
        ['user_stats', 'SELECT * FROM users', 'NONE', 'YES']
      ]

      allow(connection).to receive(:execute).and_return(query_result)

      views = adapter.fetch_views(connection)

      expect(views.length).to eq(1)
      expect(views.first[:name]).to eq('user_stats')
      expect(views.first[:definition]).to eq('SELECT * FROM users')
    end
  end

  describe '#fetch_materialized_views' do
    it 'returns empty array (MySQL does not support materialized views)' do
      expect(adapter.fetch_materialized_views(connection)).to eq([])
    end
  end

  describe '#fetch_functions' do
    it 'fetches stored procedures using SHOW CREATE' do
      query_result = [
        ['test_proc', 'PROCEDURE']
      ]

      create_result = [
        ['test_proc', 'STRICT_TRANS_TABLES', "CREATE DEFINER=`root`@`%` PROCEDURE `test_proc`(IN x INT)\nBEGIN\n  SELECT x;\nEND"]
      ]

      allow(connection).to receive(:execute).and_return(query_result)
      allow(connection).to receive(:execute).with(/SHOW CREATE PROCEDURE/).and_return(create_result)

      functions = adapter.fetch_functions(connection)

      expect(functions.length).to eq(1)
      expect(functions.first[:name]).to eq('test_proc')
      expect(functions.first[:definition]).to include('CREATE')
      expect(functions.first[:definition]).to include('PROCEDURE')
      # Note: DEFINER is in the raw definition; FunctionGenerator strips it during dump
    end
  end

  describe '#fetch_sequences' do
    it 'returns empty array (MySQL uses AUTO_INCREMENT)' do
      expect(adapter.fetch_sequences(connection)).to eq([])
    end
  end

  describe '#fetch_triggers' do
    it 'fetches triggers using SHOW CREATE' do
      query_result = [
        ['test_trigger', 'INSERT', 'users', 'AFTER']
      ]

      create_result = [
        ['test_trigger', 'STRICT_TRANS_TABLES', "CREATE DEFINER=`root`@`%` TRIGGER `test_trigger` AFTER INSERT ON `users` FOR EACH ROW BEGIN\n  INSERT INTO audit_log VALUES (NEW.id);\nEND"]
      ]

      allow(connection).to receive(:execute).and_return(query_result)
      allow(connection).to receive(:execute).with(/SHOW CREATE TRIGGER/).and_return(create_result)

      triggers = adapter.fetch_triggers(connection)

      expect(triggers.length).to eq(1)
      expect(triggers.first[:name]).to eq('test_trigger')
      expect(triggers.first[:table]).to eq('users')
      expect(triggers.first[:event]).to eq('INSERT')
      expect(triggers.first[:timing]).to eq('AFTER')
      expect(triggers.first[:definition]).to include('CREATE')
      expect(triggers.first[:definition]).to include('TRIGGER')
      # Note: DEFINER is in the raw definition; TriggerGenerator strips it during dump
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
