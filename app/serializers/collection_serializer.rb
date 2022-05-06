class CollectionSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
  has_many :publications
  has_many :items

  link(:items) { collection_items_path(object) }
end
