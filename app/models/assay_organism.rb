class AssayOrganism < ActiveRecord::Base
  belongs_to :assay, inverse_of: :assay_organisms
  belongs_to :organism, inverse_of: :assay_organisms
  belongs_to :culture_growth_type
  belongs_to :strain
  belongs_to :tissue_and_cell_type

  validates_presence_of :assay
  validates_presence_of :organism

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :assay

  scope :matches_for, -> (strain, organism, assay, culture_growth_type) do
     strain_clause = strain.nil? ? "strain_id IS NULL" : "strain_id = #{strain.id}"
     cg_clause = culture_growth_type.nil? ? "culture_growth_type_id IS NULL" : "culture_growth_type_id = #{culture_growth_type.id}"
     where("#{strain_clause} AND assay_id = ? AND organism_id = ? AND #{cg_clause}",assay.id,organism.id)
  end

  def self.exists_for? strain,organism,assay,culture_growth_type
    !AssayOrganism.matches_for(strain,organism,assay,culture_growth_type).empty?
  end

end
