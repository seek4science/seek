class PlaceholderSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
  has_many :assays
  has_one :file_template
  has_one :data_file

  attribute :data_type_annotations do
    ontology_annotations('data_type_annotations')
  end

  attribute :data_format_annotations do
    ontology_annotations('data_format_annotations')
  end

end
