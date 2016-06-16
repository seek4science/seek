module Seek
  class IsaGraphGenerator

    HIERARCHY = {
        Assay => [DataFile, Model, Sop, Publication, Sample],
        Study => [Assay],
        Investigation => [Study],
        Project => [Investigation],
        Programme => [Project]
    }

    def initialize(object, deep = false)
      @object = object
      @deep = deep
    end

    def generate
      hash = gather_children(@object)
      parent_hash = immediate_parents(@object)

      hash[:nodes] += parent_hash[:nodes]
      hash[:edges] += parent_hash[:edges]

      hash
    end

    def immediate_parents(object)
      hash = { nodes: [], edges: [] }

      parents(object).each do |parent|
        hash[:nodes] << parent
        hash[:edges] << [parent, object]
      end

      hash
    end

    def gather_children(object, parent = nil)
      nodes = [object]
      edges = parent ? [[parent, object]] : []

      children(object).each do |child|
        hash = gather_children(child, object)
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
      result = HIERARCHY.find {|k, v| v.include?(object.class) }
      if result
        parent_class = result[0]
        if object.respond_to?(parent_class.name.snakecase.pluralize.to_sym)
          object.send(parent_class.name.snakecase.pluralize.to_sym)
        else
          [object.send(parent_class.name.snakecase.to_sym)]
        end
      else
        []
      end
    end

  end
end