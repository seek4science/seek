class FileTemplateSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
  has_many :data_files
  has_many :placeholders

  attribute :edam_data do
    edam_annotations('edam_data')
  end
  attribute :edam_formats do
    edam_annotations('edam_formats')
  end

end
