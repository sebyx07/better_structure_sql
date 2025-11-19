# frozen_string_literal: true

module BetterStructureSql
  # Resolves dependencies between database objects for correct ordering
  #
  # Uses topological sorting to ensure objects are created in dependency order,
  # handling circular dependencies gracefully.
  class DependencyResolver
    attr_reader :objects, :dependencies

    def initialize
      @objects = []
      @dependencies = Hash.new { |h, k| h[k] = [] }
    end

    # Adds an object and its dependencies to the resolver
    #
    # @param name [String] Object name
    # @param type [Symbol] Object type (e.g., :table, :view, :function)
    # @param depends_on [Array<String>] Names of objects this depends on
    # @return [void]
    def add_object(name, type, depends_on: [])
      @objects << { name: name, type: type }
      @dependencies[name] = Array(depends_on)
    end

    # Resolves dependencies and returns objects in correct order
    #
    # @return [Array<String>] Object names in dependency order
    def resolve
      sorted = []
      visited = Set.new
      temp_mark = Set.new

      @objects.each do |obj|
        visit(obj[:name], visited, temp_mark, sorted) unless visited.include?(obj[:name])
      end

      sorted
    end

    private

    def visit(name, visited, temp_mark, sorted)
      if temp_mark.include?(name)
        # Circular dependency detected - return to allow best-effort ordering
        return
      end

      return if visited.include?(name)

      temp_mark.add(name)

      @dependencies[name].each do |dep|
        visit(dep, visited, temp_mark, sorted) if @objects.any? { |o| o[:name] == dep }
      end

      temp_mark.delete(name)
      visited.add(name)
      sorted << name
    end
  end
end
