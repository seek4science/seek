module WorkflowInternals
  class Output < Port
    attr_reader :sources

    def initialize(workflow, id: nil, name: nil, description: nil, type: nil, format: nil, sources: [])
      super(workflow, id: id, name: name, description: description, type: type, format: format)
      @sources = sources
    end
  end
end
