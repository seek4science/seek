class PlaceholderSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
  has_many :assays
  has_one :file_template, if: -> {has_a_file_template?}
  has_one :data_file, if: -> {has_a_data_file?}

  def has_a_file_template?
    true if object.file_template
  end
  
  def has_a_data_file?
    true if object.data_file
  end
  
  attribute :data_annotations do
    ontology_annotations('edam_data')
  end
  attribute :format_annotations do
    ontology_annotations('edam_formats')
  end

end
