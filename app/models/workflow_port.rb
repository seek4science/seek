class WorkflowPort
  attr_reader :workflow, :id, :name, :description, :format

  def initialize(workflow, id: nil, name: nil, description: nil, type: nil, format: nil)
    @workflow = workflow
    @id = id
    @name = name
    @description = description
    @type = type
    @format = format
  end

  def type
    if @type.is_a?(Array)
      @type.without('null')
    else
      @type
    end
  end

  def optional?
    @type.is_a?(Array) && @type.include?('null')
  end
end
