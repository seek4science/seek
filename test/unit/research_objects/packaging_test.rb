require 'test_helper'

class PackagingTest < ActiveSupport::TestCase
  test 'research object package path' do
    inv = FactoryBot.create(:experimental_assay, assay_assets: [FactoryBot.create(:assay_asset), FactoryBot.create(:assay_asset)]).investigation
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

  test 'fragment truncated and parameterized' do
    #should be truncated to 50 chars + id
    assay = FactoryBot.create(:assay,title:'Lorem ipsum dolor sit amet consectetur adipiscing elit. Curabitur molestie at mauris sit amet amet.')
    fragment = assay.ro_package_path_id_fragment
    assert_equal "#{assay.id}-lorem-ipsum-dolor-sit-amet-consectetur-adipiscing-",fragment
    assert_equal 50,fragment.gsub(assay.id.to_s+'-','').length
  end
end
