# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::Generators::TableGenerator do
  subject(:generator) { described_class.new(config) }

  let(:config) { BetterStructureSql::Configuration.new }

  describe '#generate' do
    context 'with simple table' do
      it 'generates CREATE TABLE statement' do
        table = {
          name: 'users',
          schema: 'public',
          columns: [
            { name: 'id', type: 'bigint', nullable: false, default: "nextval('users_id_seq'::regclass)" },
            { name: 'email', type: 'varchar', nullable: false, default: nil }
          ],
          primary_key: ['id'],
          constraints: []
        }

        result = generator.generate(table)

        expect(result).to include('CREATE TABLE IF NOT EXISTS users (')
        expect(result).to include('"id" bigint NOT NULL DEFAULT nextval(\'users_id_seq\'::regclass)')
        expect(result).to include('"email" varchar NOT NULL')
        expect(result).to include('PRIMARY KEY ("id")')
      end
    end

    context 'with nullable columns' do
      it 'omits NOT NULL constraint' do
        table = {
          name: 'posts',
          schema: 'public',
          columns: [
            { name: 'id', type: 'bigint', nullable: false, default: nil },
            { name: 'title', type: 'varchar', nullable: true, default: nil }
          ],
          primary_key: ['id'],
          constraints: []
        }

        result = generator.generate(table)

        expect(result).to include('"id" bigint NOT NULL')
        expect(result).to include('"title" varchar')
        expect(result).not_to match(/"title" varchar NOT NULL/)
      end
    end

    context 'with composite primary key' do
      it 'includes all columns in PRIMARY KEY' do
        table = {
          name: 'user_roles',
          schema: 'public',
          columns: [
            { name: 'user_id', type: 'bigint', nullable: false, default: nil },
            { name: 'role_id', type: 'bigint', nullable: false, default: nil }
          ],
          primary_key: %w[user_id role_id],
          constraints: []
        }

        result = generator.generate(table)

        expect(result).to include('PRIMARY KEY ("user_id", "role_id")')
      end
    end

    context 'with check constraint' do
      it 'includes constraint definition' do
        table = {
          name: 'products',
          schema: 'public',
          columns: [
            { name: 'id', type: 'bigint', nullable: false, default: nil },
            { name: 'price', type: 'numeric', nullable: false, default: nil }
          ],
          primary_key: ['id'],
          constraints: [
            { name: 'positive_price', type: :check, definition: 'CHECK ((price > 0))' }
          ]
        }

        result = generator.generate(table)

        expect(result).to include('CONSTRAINT positive_price CHECK ((price > 0))')
      end
    end

    context 'with unique constraint' do
      it 'includes constraint definition' do
        table = {
          name: 'users',
          schema: 'public',
          columns: [
            { name: 'id', type: 'bigint', nullable: false, default: nil },
            { name: 'email', type: 'varchar', nullable: false, default: nil }
          ],
          primary_key: ['id'],
          constraints: [
            { name: 'unique_email', type: :unique, definition: 'UNIQUE (email)' }
          ]
        }

        result = generator.generate(table)

        expect(result).to include('CONSTRAINT unique_email UNIQUE (email)')
      end
    end

    context 'with various default values' do
      it 'formats defaults correctly' do
        table = {
          name: 'test_table',
          schema: 'public',
          columns: [
            { name: 'id', type: 'bigint', nullable: false, default: nil },
            { name: 'created_at', type: 'timestamp', nullable: false, default: 'CURRENT_TIMESTAMP' },
            { name: 'is_active', type: 'boolean', nullable: false, default: 'true' },
            { name: 'count', type: 'integer', nullable: false, default: '0' },
            { name: 'status', type: 'varchar', nullable: true, default: "'pending'" }
          ],
          primary_key: ['id'],
          constraints: []
        }

        result = generator.generate(table)

        expect(result).to include('"created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP')
        expect(result).to include('"is_active" boolean NOT NULL DEFAULT true')
        expect(result).to include('"count" integer NOT NULL DEFAULT 0')
        expect(result).to include('"status" varchar DEFAULT \'pending\'')
      end
    end
  end
end
