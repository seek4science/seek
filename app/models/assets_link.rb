class AssetsLink < ApplicationRecord

  DISCUSSION = 'discussion'

  scope :discussion, -> { where(link_type:AssetsLink::DISCUSSION)}

  belongs_to :asset, polymorphic: true
  validates :url, url: { allow_nil: false }
  validates :asset, presence: true
end
