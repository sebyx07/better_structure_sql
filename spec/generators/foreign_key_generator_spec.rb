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
          column: 'user_id',
          foreign_table: 'users',
          foreign_column: 'id',
          on_update: 'NO ACTION',
          on_delete: 'NO ACTION'
        }

        result = generator.generate(fk)

        expect(result).to eq(
          'ALTER TABLE posts ADD CONSTRAINT fk_posts_user_id FOREIGN KEY (user_id) REFERENCES users (id);'
        )
      end
    end

    context 'with ON DELETE CASCADE' do
      it 'includes ON DELETE clause' do
        fk = {
          table: 'comments',
          name: 'fk_comments_post_id',
          column: 'post_id',
          foreign_table: 'posts',
          foreign_column: 'id',
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
          column: 'user_id',
          foreign_table: 'users',
          foreign_column: 'id',
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
          column: 'order_id',
          foreign_table: 'orders',
          foreign_column: 'id',
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
          column: 'customer_id',
          foreign_table: 'customers',
          foreign_column: 'id',
          on_update: 'NO ACTION',
          on_delete: 'RESTRICT'
        }

        result = generator.generate(fk)

        expect(result).to include('ON DELETE RESTRICT')
      end
    end
  end
end
