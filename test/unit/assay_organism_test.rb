require 'test_helper'

class AssayOrganismTest < ActiveSupport::TestCase
  test 'exists_for?' do
    strain = Factory :strain
    organism = strain.organism
    assay = Factory :assay
    cult = Factory :culture_growth_type
    cell_type = Factory(:tissue_and_cell_type)
    cell_type2 = Factory(:tissue_and_cell_type)

    Factory(:assay_organism)
    refute AssayOrganism.exists_for?(assay, organism, strain, cult)

    AssayOrganism.create!(strain: strain, organism: organism, assay: assay, culture_growth_type: cult)
    assert AssayOrganism.exists_for?(assay, organism, strain, cult)
    refute AssayOrganism.exists_for?(assay, organism, nil, nil)

    AssayOrganism.create!(strain: nil, organism: organism, assay: assay, culture_growth_type: nil)
    assert AssayOrganism.exists_for?(assay, organism, nil, nil)

    AssayOrganism.create!(strain: nil, organism: organism, assay: assay, culture_growth_type: cult, tissue_and_cell_type: cell_type)
    assert AssayOrganism.exists_for?(assay, organism, nil, cult)
    refute AssayOrganism.exists_for?(assay, organism, nil, cult, cell_type2)
    assert AssayOrganism.exists_for?(assay, organism, nil, cult, cell_type)
  end
end
