class FileTemplateSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
  has_many :data_files
  has_many :placeholders

  attribute :data_type_annotations do
    ontology_annotations('data_type_annotations')
  end

  attribute :data_format_annotations do
    ontology_annotations('data_format_annotations')
  end

end
