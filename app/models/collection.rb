class Collection < ApplicationRecord
  include Seek::Rdf::RdfGeneration
  include Seek::BioSchema::Support

  acts_as_asset

  validates :projects, presence: true, projects: { self: true }

  has_many :items, -> { order(:order) }, class_name: 'CollectionItem', inverse_of: :collection, dependent: :destroy
  accepts_nested_attributes_for :items, allow_destroy: true
  include HasCustomAvatar

  def self.user_creatable?
    Seek::Config.collections_enabled
  end

  def assets
    items.map(&:asset)
  end

  def show_contributor_avatars?
    false
  end

  def default_policy
    Policy.public_policy
  end
end
