class CollectionItem < ApplicationRecord
  belongs_to :asset, polymorphic: true, inverse_of: :assay_assets
  belongs_to :collection, inverse_of: :items
end
