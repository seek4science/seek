require 'test_helper'

class FairDataReaderTest < ActiveSupport::TestCase

  test 'read demo' do
    path = "#{Rails.root}/test/fixtures/files/fairdatastation/demo.ttl"

    investigations = BioInd::FairData::Reader.parse_graph(path)
    assert_equal 1, investigations.count
    inv = investigations.first
    assert_equal "http://fairbydesign.nl/ontology/inv_INV_DRP007092", inv.identifier.to_s

    assert_equal 1, inv.studies.count
    study = inv.studies.first
    assert_equal 'http://fairbydesign.nl/ontology/inv_INV_DRP007092/stu_DRP007092', study.identifier.to_s

    assert_equal 2, study.observation_units.count
    obs_unit = study.observation_units.first
    assert_equal 'http://fairbydesign.nl/ontology/inv_INV_DRP007092/stu_DRP007092/obs_HIV-1_positive', obs_unit.identifier.to_s

    assert_equal 4, obs_unit.samples.count
    sample = obs_unit.samples.first
    assert_equal 'http://fairbydesign.nl/ontology/inv_INV_DRP007092/stu_DRP007092/obs_HIV-1_positive/sam_DRS176892', sample.identifier.to_s

    assert_equal 1, sample.assays.count
    assay = sample.assays.first
    assert_equal 'http://fairbydesign.nl/ontology/inv_INV_DRP007092/stu_DRP007092/obs_HIV-1_positive/sam_DRS176892/asy_DRR243856', assay.identifier.to_s

  end

end