module Seek
  module Collectable
    extend ActiveSupport::Concern

    included do
      has_many :collection_items, as: :asset, dependent: :destroy
      has_many :collections, through: :collection_items
      has_filter collection: Seek::Filtering::Filter.new(
        value_field: 'collections.id',
        label_field: 'collections.title',
        joins: [:collections]
      )
    end
  end
end
