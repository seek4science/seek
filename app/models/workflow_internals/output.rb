module WorkflowInternals
  class Output < Port
    attr_reader :source_ids

    def initialize(structure, id: nil, name: nil, description: nil, type: nil, format: nil, source_ids: [])
      super(structure, id: id, name: name, description: description, type: type, format: format)
      @source_ids = source_ids
    end

    def sources
      source_ids.map { |i| structure.find_source(i) }.compact
    end
  end
end
