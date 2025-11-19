# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::Generators::DomainGenerator do
  subject(:generator) { described_class.new }

  describe '#generate' do
    context 'when domain has no constraint' do
      it 'generates CREATE DOMAIN statement' do
        domain = {
          name: 'positive_integer',
          schema: 'public',
          base_type: 'integer',
          constraint: nil
        }
        result = generator.generate(domain)

        expect(result).to eq('CREATE DOMAIN positive_integer AS integer;')
      end
    end

    context 'when domain has constraint' do
      it 'generates CREATE DOMAIN with constraint' do
        domain = {
          name: 'email',
          schema: 'public',
          base_type: 'character varying(255)',
          constraint: "CHECK ((VALUE ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}$'::text))"
        }
        result = generator.generate(domain)

        expect(result).to include('CREATE DOMAIN email AS character varying(255)')
        expect(result).to include('CHECK')
        expect(result).to end_with(';')
      end
    end

    context 'when domain is in custom schema' do
      it 'generates with schema prefix' do
        domain = {
          name: 'positive_number',
          schema: 'custom',
          base_type: 'numeric',
          constraint: 'CHECK ((VALUE > (0)::numeric))'
        }
        result = generator.generate(domain)

        expect(result).to start_with('CREATE DOMAIN custom.positive_number')
      end
    end

    context 'when constraint is empty string' do
      it 'generates without constraint' do
        domain = {
          name: 'simple_domain',
          schema: 'public',
          base_type: 'text',
          constraint: ''
        }
        result = generator.generate(domain)

        expect(result).to eq('CREATE DOMAIN simple_domain AS text;')
      end
    end
  end
end
