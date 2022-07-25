class FileTemplateSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
  has_many :data_files
  has_many :placeholders

  attribute :data_annotations do
    ontology_annotations('edam_data')
  end
  attribute :format_annotations do
    ontology_annotations('edam_formats')
  end

end
