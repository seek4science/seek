class AssetLink < ApplicationRecord
  DISCUSSION = 'discussion'.freeze

  scope :discussion, -> { where(link_type: AssetLink::DISCUSSION) }

  belongs_to :asset, polymorphic: true
  validates :url, url: { allow_nil: false }
  validates :asset, presence: true
end
