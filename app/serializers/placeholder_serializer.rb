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
  
  attribute :data_type_annotations do
    controlled_vocab_annotations('data_type_annotations')
  end

  attribute :data_format_annotations do
    controlled_vocab_annotations('data_format_annotations')
  end

end
