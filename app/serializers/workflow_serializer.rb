class WorkflowSerializer < ContributedResourceSerializer
  attribute :workflow_class do
    {
        title: object.workflow_class_title,
        key: object.workflow_class&.key,
        description: object.workflow_class&.description
    }
  end

  attribute :edam_operations do
    edam_annotations('edam_operations')
  end
  attribute :edam_topics do
    edam_annotations('edam_topics')
  end


  has_many :people
  has_many :projects
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :publications
  has_many :sops

  attribute :internals

  link(:diagram, if: -> { get_version.diagram_exists? }) do
    diagram_workflow_path(object, version: get_version.version)
  end
end
