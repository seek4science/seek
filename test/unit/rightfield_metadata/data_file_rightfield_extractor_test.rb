require 'test_helper'

# tests related to populating data file from rightfield metadata template
class DataFileRightFieldExtractor < ActiveSupport::TestCase
  test 'contains_rightfield_elements?' do
    data_file = Factory(:data_file, content_blob: Factory(:rightfield_master_template))
    extractor = Seek::Templates::Extract::DataFileRightFieldExtractor.new(data_file)
    assert extractor.send(:contains_rightfield_elements?)

    data_file = Factory(:blank_rightfield_master_template_data_file)
    extractor = Seek::Templates::Extract::DataFileRightFieldExtractor.new(data_file)
    assert extractor.send(:contains_rightfield_elements?)

    data_file = Factory(:xlsx_spreadsheet_datafile)
    extractor = Seek::Templates::Extract::DataFileRightFieldExtractor.new(data_file)
    refute extractor.send(:contains_rightfield_elements?)

    data_file = Factory(:small_test_spreadsheet_datafile)
    extractor = Seek::Templates::Extract::DataFileRightFieldExtractor.new(data_file)
    refute extractor.send(:contains_rightfield_elements?)
  end
end
