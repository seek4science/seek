class CollectionSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
  has_many :publications
  has_many :items

  def _links
    super.merge({ items: collection_items_path(object) })
  end
end
