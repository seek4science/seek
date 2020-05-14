class CollectionItem < ApplicationRecord
  belongs_to :asset, polymorphic: true, inverse_of: :assay_assets
  belongs_to :collection, inverse_of: :items
  validates :asset_id, uniqueness: { scope: %i[asset_type collection_id], message: 'already included in collection' }
  before_create :set_order

  private

  def set_order
    self.set_order ||= (collection.items.maximum(:order) || 0) + 1
  end
end
