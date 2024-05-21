module WorkflowInternals
  class Input < Port
    attr_reader :default_value

    def initialize(structure, id: nil, name: nil, description: nil, type: nil, format: nil, default_value: nil)
      super(structure, id: id, name: name, description: description, type: type, format: format)
      @default_value = default_value
    end
  end
end
