class AssetLink < ApplicationRecord

  DISCUSSION = 'discussion'

  scope :discussion, -> { where(link_type:AssetLink::DISCUSSION)}

  belongs_to :asset, polymorphic: true, inverse_of: :asset_links
  validates :url, url: { allow_nil: false }
  validates :asset, presence: true

end
