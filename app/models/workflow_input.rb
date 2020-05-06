class WorkflowInput < WorkflowPort
  attr_reader :default_value

  def initialize(workflow, id: nil, name: nil, description: nil, type: nil, format: nil, default_value: nil)
    super(workflow, id: id, name: name, description: description, type: type, format: format)
    @default_value = default_value
  end
end
