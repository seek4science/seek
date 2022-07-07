class PlaceholderSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
  has_many :assays
  has_one :file_template
  has_one :data_file

  attribute :edam_data do
    edam_annotations('edam_data')
  end
  attribute :edam_formats do
    edam_annotations('edam_formats')
  end

end
