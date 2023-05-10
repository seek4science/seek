require 'test_helper'

class AssayOrganismTest < ActiveSupport::TestCase
  test 'exists_for?' do
    strain = FactoryBot.create :strain
    organism = strain.organism
    assay = FactoryBot.create :assay
    cult = FactoryBot.create :culture_growth_type
    cell_type = FactoryBot.create(:tissue_and_cell_type)
    cell_type2 = FactoryBot.create(:tissue_and_cell_type)

    FactoryBot.create(:assay_organism)
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
