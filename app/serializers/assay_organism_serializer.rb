class AssayOrganismSerializer < BaseSerializer
  attributes :assay, :organism,
             :culture_growth_type, :strain, :tissue_and_cell_type

end
