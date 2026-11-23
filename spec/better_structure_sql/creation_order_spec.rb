# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::CreationOrder do
  subject(:order) { described_class.new(dependencies) }

  let(:dependencies) do
    {
      'relation:a_view' => ['relation:z_matview', 'function:rows()'],
      'function:rows()' => ['relation:orders'],
      'function:wrapper()' => ['function:rows()'],
      'function:loop_a()' => ['function:loop_b()'],
      'function:loop_b()' => ['function:loop_a()'],
      'type:even_int' => ['function:is_even(i integer)'],
      'type:pair' => ['type:even_int'],
      'type:kind' => []
    }
  end

  describe '#needs_relation?' do
    it 'is true for a routine with a relation in its signature or body' do
      expect(order.needs_relation?('function:rows()')).to be true
    end

    it 'is true for a routine that calls such a routine' do
      expect(order.needs_relation?('function:wrapper()')).to be true
    end

    it 'is false for routines without dependencies or with circular routine dependencies' do
      expect(order.needs_relation?('function:plain()')).to be false
      expect(order.needs_relation?('function:loop_a()')).to be false
    end
  end

  describe '#needs_function?' do
    it 'is true for a type whose domain CHECK calls a routine, directly or through another type' do
      expect(order.needs_function?('type:even_int')).to be true
      expect(order.needs_function?('type:pair')).to be true
    end

    it 'is false for types that only use other types' do
      expect(order.needs_function?('type:kind')).to be false
    end
  end

  describe '#sort' do
    it 'puts dependencies first and otherwise keeps the given order' do
      keyed = [['relation:a_view', :view], ['relation:b_view', :other], ['relation:z_matview', :matview], ['function:rows()', :rows]]

      expect(order.sort(keyed)).to eq(%i[matview rows view other])
    end

    it 'ignores dependencies that are not being sorted' do
      expect(order.sort([['function:rows()', :rows], ['relation:a_view', :view]])).to eq(%i[rows view])
    end

    it 'keeps every object of a dependency cycle' do
      expect(order.sort([['function:loop_a()', :a], ['function:loop_b()', :b]])).to contain_exactly(:a, :b)
    end

    it 'keeps objects with colliding keys when the database reports no dependencies' do
      expect(described_class.new({}).sort([['function:f()', :function], ['function:f()', :procedure]])).to eq(%i[function procedure])
    end
  end

  describe '.for' do
    it 'does not query databases without dependency catalogs' do
      adapter = BetterStructureSql::Adapters::BaseAdapter.allocate
      connection = double('connection')

      expect(described_class.for(adapter, connection).sort([['relation:v', :v]])).to eq([:v])
    end
  end

  it 'builds keys that match the dependency catalog format' do
    expect(described_class.relation_key('orders')).to eq('relation:orders')
    expect(described_class.type_key('mood')).to eq('type:mood')
    expect(described_class.function_key(name: 'add', arguments: 'a integer, b integer')).to eq('function:add(a integer, b integer)')
  end
end
