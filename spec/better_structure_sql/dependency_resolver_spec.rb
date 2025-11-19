# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::DependencyResolver do
  subject(:resolver) { described_class.new }

  describe '#resolve' do
    it 'returns objects in dependency order' do
      resolver.add_object('users', :table)
      resolver.add_object('posts', :table, depends_on: ['users'])
      resolver.add_object('comments', :table, depends_on: ['posts'])

      result = resolver.resolve

      expect(result.index('users')).to be < result.index('posts')
      expect(result.index('posts')).to be < result.index('comments')
    end

    it 'handles objects with no dependencies' do
      resolver.add_object('users', :table)
      resolver.add_object('roles', :table)

      result = resolver.resolve

      expect(result).to include('users', 'roles')
    end

    it 'handles multiple dependencies' do
      resolver.add_object('users', :table)
      resolver.add_object('roles', :table)
      resolver.add_object('user_roles', :table, depends_on: %w[users roles])

      result = resolver.resolve

      user_roles_idx = result.index('user_roles')
      expect(result.index('users')).to be < user_roles_idx
      expect(result.index('roles')).to be < user_roles_idx
    end

    it 'handles circular dependencies gracefully' do
      resolver.add_object('a', :table, depends_on: ['b'])
      resolver.add_object('b', :table, depends_on: ['a'])

      result = resolver.resolve

      # Should not raise error and return both objects
      expect(result).to include('a', 'b')
    end

    it 'handles complex dependency chains' do
      resolver.add_object('base', :table)
      resolver.add_object('derived1', :view, depends_on: ['base'])
      resolver.add_object('derived2', :view, depends_on: ['derived1'])
      resolver.add_object('function', :function, depends_on: ['base'])

      result = resolver.resolve

      expect(result.index('base')).to be < result.index('derived1')
      expect(result.index('derived1')).to be < result.index('derived2')
      expect(result.index('base')).to be < result.index('function')
    end

    it 'ignores dependencies on non-existent objects' do
      resolver.add_object('users', :table)
      resolver.add_object('posts', :table, depends_on: %w[users nonexistent])

      result = resolver.resolve

      expect(result.index('users')).to be < result.index('posts')
    end
  end
end
