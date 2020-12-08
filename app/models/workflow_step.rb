class WorkflowStep
  attr_reader :workflow, :id, :name, :description

  def initialize(workflow, id: nil, name: nil, description: nil)
    @workflow = workflow
    @id = id
    @name = name
    @description = description
  end
end
