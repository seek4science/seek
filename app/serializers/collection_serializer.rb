class CollectionSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
  has_many :publications
  has_many :items

  def items
    object.items.map do |item|
      { type: item.asset_type.underscore.pluralize, id: item.asset_id.to_s, meta: { comment: item.comment } }
    end
  end
end
