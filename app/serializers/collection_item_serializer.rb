class CollectionItemSerializer < SimpleBaseSerializer
  include Rails.application.routes.url_helpers

  belongs_to :collection
  has_one :asset, polymorphic: true, if: -> { object.asset.can_view? } do
    meta title: object.asset.title
  end

  attributes :comment, :order

  link(:self) { collection_item_path(object.collection, object) }
end
