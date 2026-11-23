# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::Generators::TypeGenerator do
  subject(:generator) { described_class.new }

  describe '#generate' do
    it 'quotes the enum name and escapes values, keeping their order' do
      type = { name: 'OrderStatus', schema: 'public', type: 'enum', values: ['pending', "it's shipped", 'done'] }

      expect(generator.generate(type)).to eq(%(CREATE TYPE "OrderStatus" AS ENUM ('pending', 'it''s shipped', 'done');))
    end

    it 'quotes composite attribute names' do
      type = { name: 'address', schema: 'public', type: 'composite',
               attributes: [{ name: 'Street', type: 'character varying(120)' }, { name: 'zip', type: 'character(5)' }] }

      expect(generator.generate(type)).to eq('CREATE TYPE "address" AS ("Street" character varying(120), "zip" character(5));')
    end

    it 'renders range types with optional settings' do
      type = { name: 'float_range', schema: 'public', type: 'range', subtype: 'double precision',
               subtype_opclass: nil, collation: nil, canonical: nil, subtype_diff: 'float8mi' }

      expect(generator.generate(type)).to eq(
        'CREATE TYPE "float_range" AS RANGE (SUBTYPE = double precision, SUBTYPE_DIFF = float8mi);'
      )
    end

    it 'delegates domains to the domain generator' do
      type = { name: 'positive_int', schema: 'public', type: 'domain', base_type: 'integer',
               constraints: [{ name: 'positive_int_check', definition: 'CHECK ((VALUE > 0))' }] }

      expect(generator.generate(type)).to eq(
        'CREATE DOMAIN "positive_int" AS integer CONSTRAINT "positive_int_check" CHECK ((VALUE > 0));'
      )
    end

    it 'schema-qualifies types outside public' do
      type = { name: 'mood', schema: 'app', type: 'enum', values: %w[happy] }

      expect(generator.generate(type)).to eq(%(CREATE TYPE "app"."mood" AS ENUM ('happy');))
    end

    it 'skips unknown type categories' do
      expect(generator.generate({ name: 'x', schema: 'public', type: 'unknown' })).to be_nil
    end
  end
end
