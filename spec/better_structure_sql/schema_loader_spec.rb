# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'

RSpec.describe BetterStructureSql::SchemaLoader do
  let(:temp_dir)     { Pathname.new(Dir.mktmpdir) }
  let(:schema_dir)   { temp_dir.join('schema') }
  let(:executed)     { [] }
  let(:connection)   { double('connection', adapter_name:) }
  let(:adapter_name) { 'PostgreSQL' }
  let(:loader)       { described_class.new(BetterStructureSql::Configuration.new) }

  before do
    allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
    allow(connection).to receive(:execute) { |sql| executed << sql }
  end

  after { FileUtils.rm_rf(temp_dir) }

  def write(relative_path, content)
    path = schema_dir.join(relative_path)
    FileUtils.mkdir_p(path.dirname)
    File.write(path, content)
  end

  describe '#load with a directory' do
    it 'executes the header first, then files in dependency order' do
      write('20_migrations/000001.sql', 'migrations')
      write('05_tables/000002.sql', 'tables 2')
      write('05_tables/000001.sql', 'tables 1')
      write('01_extensions/000001.sql', 'extensions')
      write('10_comments/000001.sql', 'comments')
      write('_header.sql', 'header')
      write('_manifest.json', '{}')

      loader.load(schema_dir)

      expect(executed).to eq(['header', 'extensions', 'tables 1', 'tables 2', 'comments', 'migrations'])
    end

    context 'with MySQL' do
      let(:adapter_name) { 'Mysql2' }

      it 'skips the empty header instead of sending an empty query' do
        write('_header.sql', '')
        write('05_tables/000001.sql', "CREATE TABLE a (id int);\n\nCREATE TABLE b (id int);\n")

        loader.load(schema_dir)

        expect(executed).to eq(['CREATE TABLE a (id int)', 'CREATE TABLE b (id int)'])
      end

      it 'keeps nested BEGIN ... END blocks and control flow inside one statement' do
        procedure = <<~SQL.strip
          CREATE PROCEDURE `bump`(IN account INT)
          BEGIN
            DECLARE done INT DEFAULT 0;
            inner_block: BEGIN
              UPDATE accounts SET quantity = quantity + 1 WHERE id = account;
            END inner_block;
            IF done = 0 THEN
              SELECT 1;
            END IF;
          END
        SQL
        trigger = "CREATE TRIGGER `t` BEFORE INSERT ON `accounts` FOR EACH ROW BEGIN\n  SET NEW.a = 1;\nEND"
        write('03_functions/000001.sql', "-- Functions\n\n#{procedure};\n\nCREATE FUNCTION `f`() RETURNS int RETURN 1;\n")
        write('09_triggers/000001.sql', "#{trigger};\n")

        loader.load(schema_dir)

        expect(executed).to eq([procedure, 'CREATE FUNCTION `f`() RETURNS int RETURN 1', trigger])
      end

      it 'does not let query log tags into routine bodies, and restores them afterwards' do
        tagger = ->(sql, _connection) { "#{sql} /*application='App'*/" }
        original = ActiveRecord.query_transformers
        ActiveRecord.query_transformers = [tagger]
        allow(connection).to receive(:execute) do |sql|
          executed << ActiveRecord.query_transformers.reduce(sql) { |memo, transformer| transformer.call(memo, connection) }
        end
        write('03_functions/000001.sql', "CREATE FUNCTION `f`() RETURNS int RETURN 1;\n")

        loader.load(schema_dir)

        expect(executed).to eq(['CREATE FUNCTION `f`() RETURNS int RETURN 1'])
        expect(ActiveRecord.query_transformers).to eq([tagger])
      ensure
        ActiveRecord.query_transformers = original
      end
    end

    context 'with SQLite' do
      let(:adapter_name)   { 'SQLite' }
      let(:raw_connection) { double('raw connection') }

      it 'runs the multi-statement header through execute_batch' do
        allow(connection).to receive(:raw_connection).and_return(raw_connection)
        allow(raw_connection).to receive(:execute_batch) { |sql| executed << sql }
        header = "PRAGMA foreign_keys = ON;\nPRAGMA defer_foreign_keys = ON;"
        write('_header.sql', header)

        loader.load(schema_dir)

        expect(executed).to eq([header])
      end
    end
  end

  describe '#load with a file' do
    it 'executes the file content' do
      file = temp_dir.join('structure.sql')
      File.write(file, 'CREATE TABLE a ();')

      loader.load(file)

      expect(executed).to eq(['CREATE TABLE a ();'])
    end

    it 'propagates statement failures' do
      file = temp_dir.join('structure.sql')
      File.write(file, 'BROKEN;')
      allow(connection).to receive(:execute).and_raise(ActiveRecord::StatementInvalid, 'syntax error')

      expect { loader.load(file) }.to raise_error(ActiveRecord::StatementInvalid, /syntax error/)
    end
  end

  it 'raises LoadError when the path does not exist' do
    expect { loader.load(temp_dir.join('missing')) }.to raise_error(described_class::LoadError, /not found/)
  end
end
