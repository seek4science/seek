class RelationshipType < ActiveRecord::Base
  has_many :assay_assets
  validates_uniqueness_of :key
  validates_presence_of :key
end
