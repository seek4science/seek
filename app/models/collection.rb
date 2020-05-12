class Collection < ApplicationRecord
  include Seek::Rdf::RdfGeneration
  include Seek::BioSchema::Support

  acts_as_asset

  validates :projects, presence: true, projects: { self: true }

  has_many :items, class_name: 'CollectionItem', inverse_of: :collection

  def self.user_creatable?
    Seek::Config.collections_enabled
  end

  def assets
    items.map(&:asset)
  end
end
