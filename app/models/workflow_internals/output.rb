module WorkflowInternals
  class Output < Port
    attr_reader :source_ids

    def initialize(workflow, id: nil, name: nil, description: nil, type: nil, format: nil, source_ids: [])
      super(workflow, id: id, name: name, description: description, type: type, format: format)
      @source_ids = source_ids
    end

    def sources
      source_ids.map { |i| structure.find_source(i) }.compact
    end
  end
end
