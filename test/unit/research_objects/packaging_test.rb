require 'test_helper'

class PackagingTest < ActiveSupport::TestCase
  test 'research object package path' do
    inv = Factory(:experimental_assay, assay_assets: [Factory(:assay_asset), Factory(:assay_asset)]).investigation
    # for inv
    assert_equal '', inv.research_object_package_path

    # for study
    study = inv.studies.first
    assert_equal '', study.research_object_package_path
    assert_equal "#{study.ro_package_path_fragment}", study.research_object_package_path([inv])

    # for assay
    assay = study.assays.first
    assert_equal '', assay.research_object_package_path
    assert_equal "#{assay.ro_package_path_fragment}", assay.research_object_package_path([study])
    assert_equal "#{study.ro_package_path_fragment}#{assay.ro_package_path_fragment}", assay.research_object_package_path([inv, study])

    # for data file in an assay
    data_file = inv.related_data_files.first
    assert_equal "data_files/#{data_file.ro_package_path_id_fragment}/", data_file.research_object_package_path
    assert_equal "data_files/#{data_file.ro_package_path_id_fragment}/", data_file.research_object_package_path([assay])
    assert_equal "data_files/#{data_file.ro_package_path_id_fragment}/", data_file.research_object_package_path([study, assay])
    assert_equal "data_files/#{data_file.ro_package_path_id_fragment}/", data_file.research_object_package_path([inv, study, assay])
  end
end
