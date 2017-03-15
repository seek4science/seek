require 'test_helper'

class AssayOrganismTest < ActiveSupport::TestCase
  test 'exists_for?' do
    strain = Factory :strain
    organism = strain.organism
    assay = Factory :assay
    cult = Factory :culture_growth_type

    ao = Factory :assay_organism

    refute AssayOrganism.exists_for?(strain, organism, assay, cult)

    ao = AssayOrganism.create strain: strain, organism: organism, assay: assay, culture_growth_type: cult

    assert AssayOrganism.exists_for? strain, organism, assay, cult

    refute AssayOrganism.exists_for? nil, organism, assay, nil

    ao = AssayOrganism.create strain: nil, organism: organism, assay: assay, culture_growth_type: nil

    assert AssayOrganism.exists_for? nil, organism, assay, nil
  end
end
