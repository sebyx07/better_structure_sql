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
          constraints: []
        }
        result = generator.generate(domain)

        expect(result).to eq('CREATE DOMAIN "positive_integer" AS integer;')
      end
    end

    context 'when domain has constraint' do
      it 'generates CREATE DOMAIN with constraint' do
        domain = {
          name: 'email',
          schema: 'public',
          base_type: 'character varying(255)',
          constraints: [
            { name: 'email_check', definition: "CHECK ((VALUE ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}$'::text))" }
          ]
        }
        result = generator.generate(domain)

        expect(result).to include('CREATE DOMAIN "email" AS character varying(255) CONSTRAINT "email_check" CHECK')
        expect(result).to end_with(';')
      end
    end

    context 'when domain is in custom schema' do
      it 'generates with schema prefix' do
        domain = {
          name: 'positive_number',
          schema: 'custom',
          base_type: 'numeric',
          constraints: [{ name: 'positive_number_check', definition: 'CHECK ((VALUE > (0)::numeric))' }]
        }
        result = generator.generate(domain)

        expect(result).to start_with('CREATE DOMAIN "custom"."positive_number"')
      end
    end

    context 'when domain has a default, NOT NULL and several constraints' do
      it 'keeps every part in order' do
        domain = {
          name: 'email',
          schema: 'public',
          base_type: 'text',
          default: "'nobody@example.com'::text",
          not_null: true,
          constraints: [
            { name: 'email_has_at', definition: "CHECK ((VALUE ~ '@'::text))" },
            { name: 'email_not_blank', definition: "CHECK ((VALUE <> ''::text))" }
          ]
        }
        result = generator.generate(domain)

        expect(result).to eq(
          "CREATE DOMAIN \"email\" AS text DEFAULT 'nobody@example.com'::text NOT NULL " \
          "CONSTRAINT \"email_has_at\" CHECK ((VALUE ~ '@'::text)) " \
          "CONSTRAINT \"email_not_blank\" CHECK ((VALUE <> ''::text));"
        )
      end
    end
  end
end
