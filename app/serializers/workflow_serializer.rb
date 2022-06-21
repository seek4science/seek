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
  has_many :presentations
  has_many :data_files
  has_many :documents

  attribute :internals

  link(:diagram, if: -> () { (@scope.try(:[], :requested_version) || object).diagram_exists? }) do |s|
    diagram_workflow_path(object, version: (@scope.try(:[], :requested_version) || object).version)
  end
end
