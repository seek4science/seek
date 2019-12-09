class WorkflowPort
  attr_reader :workflow, :id, :name, :description, :type, :format

  def initialize(workflow, id: nil, name: nil, description: nil, type: nil, format: nil)
    @workflow = workflow
    @id = id
    @name = name
    @description = description
    @type = type
    @format = format
  end
end
