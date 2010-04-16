class AssayOrganism < ActiveRecord::Base
  belongs_to :assay
  belongs_to :organism

  validates_presence_of :assay
  validates_presence_of :organism
end
