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

    sugar_and_strain_names = platemap_reader.read_in(df)

    sugar_set = Set.new(['Raf', 'Gal'])
    strain_set = Set.new(['WT', 'GAL1', 'GAL2', 'GAL3', 'GAL7', 'GAL80', 'GAL10'])

    expected_s_and_s_names = {:sugar_names => sugar_set, :strain_names => strain_set}

    assert_equal(expected_s_and_s_names, sugar_and_strain_names)
  end
end