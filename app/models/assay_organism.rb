class AssayOrganism < ActiveRecord::Base
  belongs_to :assay
  belongs_to :organism
  belongs_to :culture_growth_type
  belongs_to :strain
  belongs_to :tissue_and_cell_type

  validates_presence_of :assay
  validates_presence_of :organism

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :assay

end
