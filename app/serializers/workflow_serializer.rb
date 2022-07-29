class WorkflowSerializer < ContributedResourceSerializer
  attribute :workflow_class do
    {
        title: object.workflow_class_title,
        key: object.workflow_class&.key,
        description: object.workflow_class&.description
    }
  end

  attribute :operation_annotations do
    controlled_vocab_annotations('operation_annotations')
  end
  attribute :topic_annotations do
    controlled_vocab_annotations('topic_annotations')
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

  link(:diagram, if: -> { get_version.diagram_exists? }) do
    diagram_workflow_path(object, version: get_version.version)
  end
end
