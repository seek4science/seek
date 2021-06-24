module WorkflowInternals
  class Step < Part
    attr_reader :workflow, :id, :name, :description, :sources, :sinks

    def initialize(structure, id: nil, name: nil, description: nil, sources: [], sinks: [])
      super(structure, id: id)
      @name = name
      @description = description
      @sources = sources
      @sinks = sinks
    end
  end
end
