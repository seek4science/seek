module WorkflowInternals
  class Step < Part
    attr_reader :workflow, :id, :name, :description, :sink_ids

    def initialize(structure, id: nil, name: nil, description: nil, sink_ids: [])
      super(structure, id: id)
      @name = name
      @description = description
      @sink_ids = sink_ids
    end
  end
end
