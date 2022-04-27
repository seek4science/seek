class DataFileSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :publications
  has_many :events
  has_many :workflows
end
