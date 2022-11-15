module WorkflowInternals
  class Link < Part
    attr_reader :id, :name, :source_id, :sink_id, :default_value

    def initialize(structure, id: nil, name: nil, source_id: nil, sink_id: nil, default_value: nil)
      super(structure, id: id)
      @name = name
      @source_id = source_id
      @sink_id = sink_id
      @default_value = default_value
    end

    def source
      structure.find_source(source_id)
    end

    def sink
      structure.find_part(sink_id)
    end
  end
end
