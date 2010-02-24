class RelationshipType < ActiveRecord::Base
  has_many :assay_assets
end
