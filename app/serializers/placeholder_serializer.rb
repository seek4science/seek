class PlaceholderSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
  has_many :assays
  has_one :file_template
  has_one :data_file

  attribute :data_annotations do
    ontology_annotations('data_annotations')
  end
  attribute :format_annotations do
    ontology_annotations('format_annotations')
  end

end
