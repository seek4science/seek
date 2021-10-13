class AssetLink < ApplicationRecord
  DISCUSSION = 'discussion'.freeze
  SOURCE = 'source'.freeze

  scope :discussion, -> { where(link_type: AssetLink::DISCUSSION) }

  belongs_to :asset, polymorphic: true
  validates :url, url: { allow_nil: false }
  validates :label, length: {maximum: 100}
  validates :asset, presence: true

  before_validation :strip_url

  def display_label
    label.blank? ? url : label
  end

  private

  def strip_url
    url&.strip!
  end
end
