require 'test_helper'

# tests related to populating data file from rightfield metadata template
class RightfieldMetadataPopulationTest < ActiveSupport::TestCase

  test 'basic metadata population' do
    blob = Factory(:rightfield_base_sample_template1)
    data_file=DataFile.new(content_blob:blob)
    assert data_file.contains_extractable_spreadsheet?

    data_file.populate_metadata_from_template

    assert_equal 'My Title',data_file.title
    assert_equal 'My Description',data_file.description

  end

  test 'handles none excel blob' do
    blob = Factory(:txt_content_blob)
    data_file=DataFile.new(content_blob:blob)
    refute data_file.contains_extractable_spreadsheet?

    data_file.populate_metadata_from_template

    assert_nil data_file.title
    assert_nil data_file.description
  end

  test 'handles none rightfield blob' do
    blob = Factory(:small_test_spreadsheet_content_blob)
    data_file=DataFile.new(content_blob:blob)
    assert data_file.contains_extractable_spreadsheet?

    data_file.populate_metadata_from_template

    assert_nil data_file.title
    assert_nil data_file.description
  end


end