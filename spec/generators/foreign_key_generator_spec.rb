# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::Generators::ForeignKeyGenerator do
  subject(:generator) { described_class.new }

  describe '#generate' do
    context 'with simple foreign key' do
      it 'generates ALTER TABLE ADD CONSTRAINT statement' do
        fk = {
          table: 'posts',
          name: 'fk_posts_user_id',
          columns: ['user_id'],
          foreign_table: 'users',
          foreign_columns: ['id'],
          on_update: 'NO ACTION',
          on_delete: 'NO ACTION'
        }

        result = generator.generate(fk)

        expect(result).to eq(
          'ALTER TABLE "posts" ADD CONSTRAINT "fk_posts_user_id" FOREIGN KEY ("user_id") REFERENCES "users" ("id");'
        )
      end
    end

    context 'with a composite key on reserved-word columns' do
      it 'quotes every column of both sides in key order' do
        fk = {
          table: 'entries', name: 'fk_entries_order', columns: %w[order key], foreign_table: 'orders',
          foreign_columns: %w[order key], on_update: 'NO ACTION', on_delete: 'CASCADE'
        }

        expect(generator.generate(fk)).to eq(
          'ALTER TABLE "entries" ADD CONSTRAINT "fk_entries_order" FOREIGN KEY ("order", "key") ' \
          'REFERENCES "orders" ("order", "key") ON DELETE CASCADE;'
        )
      end
    end

    context 'with ON DELETE CASCADE' do
      it 'includes ON DELETE clause' do
        fk = {
          table: 'comments',
          name: 'fk_comments_post_id',
          columns: ['post_id'],
          foreign_table: 'posts',
          foreign_columns: ['id'],
          on_update: 'NO ACTION',
          on_delete: 'CASCADE'
        }

        result = generator.generate(fk)

        expect(result).to include('ON DELETE CASCADE')
        expect(result).not_to include('ON UPDATE')
      end
    end

    context 'with ON UPDATE SET NULL' do
      it 'includes ON UPDATE clause' do
        fk = {
          table: 'audit_logs',
          name: 'fk_audit_logs_user_id',
          columns: ['user_id'],
          foreign_table: 'users',
          foreign_columns: ['id'],
          on_update: 'SET NULL',
          on_delete: 'NO ACTION'
        }

        result = generator.generate(fk)

        expect(result).to include('ON UPDATE SET NULL')
        expect(result).not_to include('ON DELETE')
      end
    end

    context 'with both CASCADE actions' do
      it 'includes both clauses' do
        fk = {
          table: 'line_items',
          name: 'fk_line_items_order_id',
          columns: ['order_id'],
          foreign_table: 'orders',
          foreign_columns: ['id'],
          on_update: 'CASCADE',
          on_delete: 'CASCADE'
        }

        result = generator.generate(fk)

        expect(result).to include('ON DELETE CASCADE')
        expect(result).to include('ON UPDATE CASCADE')
      end
    end

    context 'with RESTRICT action' do
      it 'includes ON DELETE RESTRICT' do
        fk = {
          table: 'invoices',
          name: 'fk_invoices_customer_id',
          columns: ['customer_id'],
          foreign_table: 'customers',
          foreign_columns: ['id'],
          on_update: 'NO ACTION',
          on_delete: 'RESTRICT'
        }

        result = generator.generate(fk)

        expect(result).to include('ON DELETE RESTRICT')
      end
    end

    context 'with a PostgreSQL constraint definition' do
      it 'uses the full definition, keeping MATCH, DEFERRABLE and NOT VALID' do
        fk = {
          table: 'Orders',
          name: 'orders_account_fk',
          definition: 'FOREIGN KEY (code, region) REFERENCES accounts(code, region) MATCH FULL ON DELETE SET NULL DEFERRABLE NOT VALID'
        }

        expect(generator.generate(fk)).to eq(
          'ALTER TABLE "Orders" ADD CONSTRAINT "orders_account_fk" FOREIGN KEY (code, region) ' \
          'REFERENCES accounts(code, region) MATCH FULL ON DELETE SET NULL DEFERRABLE NOT VALID;'
        )
      end
    end
  end
end
