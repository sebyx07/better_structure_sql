# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::Generators::SequenceGenerator do
  subject(:generator) { described_class.new }

  describe '#generate' do
    it 'renders a bigint sequence with only non-default options' do
      sequence = { name: 'orders_id_seq', data_type: 'bigint', start_value: 1, increment: 1,
                   min_value: 1, max_value: 9_223_372_036_854_775_807, cache_size: 1, cycle: false }

      expect(generator.generate(sequence)).to eq(<<~SQL.strip)
        CREATE SEQUENCE IF NOT EXISTS "orders_id_seq"
          START WITH 1
          MINVALUE 1
          MAXVALUE 9223372036854775807;
      SQL
    end

    it 'keeps the data type of non-bigint sequences and every custom option' do
      sequence = { name: 'Invoice_seq', data_type: 'integer', start_value: 1000, increment: 5,
                   min_value: 1000, max_value: 999_999, cache_size: 10, cycle: true }

      expect(generator.generate(sequence)).to eq(<<~SQL.strip)
        CREATE SEQUENCE IF NOT EXISTS "Invoice_seq"
          AS integer
          START WITH 1000
          INCREMENT BY 5
          MINVALUE 1000
          MAXVALUE 999999
          CACHE 10
          CYCLE;
      SQL
    end
  end

  describe '#options' do
    it 'returns the option clauses shared with identity columns' do
      expect(generator.options({ start_value: 100, increment: 10, cache_size: 1, cycle: false }))
        .to eq(['START WITH 100', 'INCREMENT BY 10'])
    end
  end
end
