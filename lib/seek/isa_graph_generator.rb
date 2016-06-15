module Seek
  class IsaGraphGenerator

    HIERARCHY = {
        Assay => [DataFile, Model, Sop, Publication, Sample],
        Study => [Assay],
        Investigation => [Study],
        Project => [Investigation],
        Programme => [Project]
    }

    def initialize(object)
      @object = object
    end

    def generate
      gather(@object)
    end

    def gather(object, parent = nil)
      nodes = [object]
      edges = parent ? [[parent, object]] : []

      children(object).each do |child|
        hash = gather(child, object)
        nodes += hash[:nodes]
        edges += hash[:edges]
      end

      { nodes: nodes, edges: edges }
    end

    private

    def children(object)
      (HIERARCHY[object.class] || []).map do |c|
        object.send(c.name.snakecase.pluralize.to_sym)
      end.flatten
    end

    def parents(object)
      result = HIERARCHY.find {|k, v| v.include?(object) }
      if result
        result[0].map do |c|
          if object.respond_to?(c.name.snakecase.pluralize.to_sym)
            object.send(c.name.snakecase.pluralize.to_sym)
          else
            [object.send(c.name.snakecase.to_sym)]
          end
        end.flatten
      else
        []
      end
    end

  end
end