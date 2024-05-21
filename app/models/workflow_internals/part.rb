module WorkflowInternals
  class Part
    attr_reader :structure, :id

    def initialize(structure, id: nil)
      @structure = structure
      @id = id
    end

    def nice_id
      id.split(/[\#\/]/).last if id
    end

    def inspect
      "#<#{self.class.name} id=\"#{id}\">"
    end

    def workflow
      structure.workflow
    end
  end
end
