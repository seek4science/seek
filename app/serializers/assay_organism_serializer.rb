class AssayOrganismSerializer < BaseSerializer
  attributes :id, :assay, :organism,
             :culture_growth_type, :strain, :tissue_and_cell_type

end
