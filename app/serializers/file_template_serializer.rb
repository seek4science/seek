class FileTemplateSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
  has_many :data_files
  has_many :placeholders

end
