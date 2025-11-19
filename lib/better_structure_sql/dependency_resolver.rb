module BetterStructureSql
  class DependencyResolver
    attr_reader :objects, :dependencies

    def initialize
      @objects = []
      @dependencies = Hash.new { |h, k| h[k] = [] }
    end

    def add_object(name, type, depends_on: [])
      @objects << {name: name, type: type}
      @dependencies[name] = Array(depends_on)
    end

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
