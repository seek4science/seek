class DataFileSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :publications
  has_many :events
  has_many :workflows
  has_one :placeholder, if:  -> {has_a_placeholder?}
  has_one :file_template, if:  -> {has_a_file_template?}

  def has_a_placeholder?
    true if object.placeholder
  end
  
  def has_a_file_template?
    true if object.file_template
  end
  
end
