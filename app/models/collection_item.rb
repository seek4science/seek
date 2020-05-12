class CollectionItem < ApplicationRecord
  belongs_to :asset, polymorphic: true, inverse_of: :assay_assets
  belongs_to :collection, inverse_of: :items
  validates :asset_id, uniqueness: { scope: %i[asset_type collection_id], message: 'already included in collection' }
end
