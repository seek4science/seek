require 'test_helper'

class PackagingTest < ActiveSupport::TestCase

  test "research object package path" do
    inv = Factory(:experimental_assay,:assay_assets=>[Factory(:assay_asset),Factory(:assay_asset)]).investigation
    #for inv
    assert_equal "investigations/#{inv.id}/",inv.research_object_package_path

    #for study
    study = inv.studies.first
    assert_equal "investigations/#{inv.id}/studies/#{study.id}/",study.research_object_package_path

    #for assay
    assay = study.assays.first
    assert_equal "investigations/#{inv.id}/studies/#{study.id}/assays/#{assay.id}/",assay.research_object_package_path

    #for data file in an assay
    data_file = inv.related_data_files.first
    assert_equal "data_files/#{data_file.id}/",data_file.research_object_package_path
  end

end