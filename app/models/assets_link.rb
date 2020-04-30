class AssetsLink < ApplicationRecord
  belongs_to :asset, polymorphic: true
  validates :url, url: { allow_nil: false }
  validates :asset, presence: true
end
