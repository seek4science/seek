class FileTemplateSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
  has_many :data_files
  has_many :placeholders

  attribute :edam_operations do
    edam_annotations('edam_data')
  end
  attribute :edam_topics do
    edam_annotations('edam_formats')
  end

end
