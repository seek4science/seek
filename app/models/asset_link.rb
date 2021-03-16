class AssetLink < ApplicationRecord
  DISCUSSION = 'discussion'.freeze
  MISC_LINKS = 'misc'.freeze

  scope :discussion, -> { where(link_type: AssetLink::DISCUSSION) }
  scope :misc_link, -> { where(link_type: AssetLink::MISC_LINKS) }

  belongs_to :asset, polymorphic: true
  validates :url, url: { allow_nil: false }
  validates :label, length: {maximum: 100}
  validates :asset, presence: true

  def display_label
    label.blank? ? url : label
  end
end
