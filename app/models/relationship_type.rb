class RelationshipType < ActiveRecord::Base
  VALIDATION='VALIDATION'
  CONSTRUCTION='CONSTRUCTION'
  SIMULATION='SIMULATION'
  has_many :assay_assets
  validates_uniqueness_of :key
  validates_presence_of :key
end
