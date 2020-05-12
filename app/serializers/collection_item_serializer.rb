class CollectionSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
  has_many :publications
end
