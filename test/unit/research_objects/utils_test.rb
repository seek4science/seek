require 'test_helper'
class GeneratorTest < ActiveSupport::TestCase

  include Seek::ResearchObjects::Utils

  test "path for item" do
    inv = Factory(:experimental_assay,:assay_assets=>[Factory(:assay_asset),Factory(:assay_asset)]).investigation
    #for inv
    assert_equal "investigations/#{inv.id}/",path_for_item(inv)

    #for study
    study = inv.studies.first
    assert_equal "investigations/#{inv.id}/studies/#{study.id}/",path_for_item(study)

    #for assay
    assay = study.assays.first
    assert_equal "investigations/#{inv.id}/studies/#{study.id}/assays/#{assay.id}/",path_for_item(assay)

  end

  test "uri for item" do
    inv = Factory(:experimental_assay,:assay_assets=>[Factory(:assay_asset),Factory(:assay_asset)]).investigation

    #for inv
    assert_equal "http://localhost:3000/investigations/#{inv.id}",uri_for_item(inv)

    #for study
    study = inv.studies.first
    assert_equal "http://localhost:3000/studies/#{study.id}",uri_for_item(study)

    #for assay
    assay = study.assays.first
    assert_equal "http://localhost:3000/assays/#{assay.id}",uri_for_item(assay)
  end

end