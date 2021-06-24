module WorkflowInternals
  class Part
    attr_reader :structure, :id

    def initialize(structure, id: nil)
      @structure = structure
      @id = id
    end

    def nice_id
      id.split(/[\#\/]/).last
    end
  end
end
