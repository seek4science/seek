class AssayOrganism < ApplicationRecord
  belongs_to :assay, inverse_of: :assay_organisms
  belongs_to :organism, inverse_of: :assay_organisms
  belongs_to :culture_growth_type
  belongs_to :strain
  belongs_to :tissue_and_cell_type

  validates_presence_of :assay
  validates_presence_of :organism

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :assay

  def self.exists_for?(assay, organism, strain, culture_growth_type, tissue_and_cell_type = nil)
    ao = AssayOrganism.where(assay_id: assay, organism_id: organism, strain_id: strain,
                             culture_growth_type_id: culture_growth_type)
    ao = ao.where(tissue_and_cell_type_id: tissue_and_cell_type) if tissue_and_cell_type
    ao.exists?
  end

end
