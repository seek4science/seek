require 'test_helper'
require 'set'

class PlatemapReaderTest < ActiveSupport::TestCase

  test "read in platemap" do

    df = Factory(:data_file,
                 :content_blob => Factory(:spreadsheet_content_blob,
                                          :data => File.new("#{Rails.root}/test/fixtures/files/rdf/GALgenes_contents.xlsx",
                                                            "rb").read))

    blob = df.content_blob

    platemap_reader = PlatemapReader.new

    actual_sample_set = platemap_reader.read_in(df)

    expected_sample_set = Set.new [[nil, 'Raf'], [nil, 'Gal'], ['WT', 'Raf'], ['WT', 'Gal'], ['GAL1', 'Raf'], ['GAL1', 'Gal'],
                                   ['GAL2', 'Raf'], ['GAL2', 'Gal'], ['GAL3', 'Raf'], ['GAL3', 'Gal'], ['GAL7', 'Raf'],
                                   ['GAL7', 'Gal'], ['GAL10', 'Raf'], ['GAL10', 'Gal'], ['GAL80', 'Raf'], ['GAL80', 'Gal']]

    assert_equal(expected_sample_set, actual_sample_set)
  end
end
