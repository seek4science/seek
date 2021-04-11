class FileTemplateSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
end
