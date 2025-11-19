# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::Generators::IndexGenerator do
  subject(:generator) { described_class.new }

  describe '#generate' do
    context 'when index definition has semicolon' do
      it 'returns definition as-is' do
        index = {
          schema: 'public',
          table: 'users',
          name: 'index_users_on_email',
          definition: 'CREATE INDEX index_users_on_email ON public.users USING btree (email);'
        }

        result = generator.generate(index)

        expect(result).to eq('CREATE INDEX index_users_on_email ON public.users USING btree (email);')
      end
    end

    context 'when index definition lacks semicolon' do
      it 'adds semicolon' do
        index = {
          schema: 'public',
          table: 'users',
          name: 'index_users_on_email',
          definition: 'CREATE INDEX index_users_on_email ON public.users USING btree (email)'
        }

        result = generator.generate(index)

        expect(result).to eq('CREATE INDEX index_users_on_email ON public.users USING btree (email);')
      end
    end

    context 'with unique index' do
      it 'preserves UNIQUE keyword' do
        index = {
          schema: 'public',
          table: 'users',
          name: 'index_users_on_username',
          definition: 'CREATE UNIQUE INDEX index_users_on_username ON public.users USING btree (username)'
        }

        result = generator.generate(index)

        expect(result).to include('CREATE UNIQUE INDEX')
      end
    end

    context 'with partial index' do
      it 'preserves WHERE clause' do
        index = {
          schema: 'public',
          table: 'users',
          name: 'index_active_users',
          definition: 'CREATE INDEX index_active_users ON public.users USING btree (email) WHERE (deleted_at IS NULL)'
        }

        result = generator.generate(index)

        expect(result).to include('WHERE (deleted_at IS NULL)')
      end
    end
  end
end
