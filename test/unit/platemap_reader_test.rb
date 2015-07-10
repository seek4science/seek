require 'test_helper'
require 'set'
require 'csv'
include SysMODB::SpreadsheetExtractor

class PlatemapReaderTest < ActiveSupport::TestCase

  expected_sample_set = Set.new [[nil, 'Raf'], [nil, 'Gal'], ['WT', 'Raf'], ['WT', 'Gal'], ['GAL1', 'Raf'], ['GAL1', 'Gal'],
                                 ['GAL2', 'Raf'], ['GAL2', 'Gal'], ['GAL3', 'Raf'], ['GAL3', 'Gal'], ['GAL7', 'Raf'],
                                 ['GAL7', 'Gal'], ['GAL10', 'Raf'], ['GAL10', 'Gal'], ['GAL80', 'Raf'], ['GAL80', 'Gal']]

  test "read in platemap" do

    #   df = Factory(:data_file,
    #               :content_blob => Factory(:spreadsheet_content_blob,
    #                                       :data => File.new("#{Rails.root}/test/fixtures/files/rdf/GALgenes_contents.xlsx",
    #                                                        "rb").read))

    csv_data = spreadsheet_to_csv(open("#{Rails.root}/test/fixtures/files/rdf/GALgenes_contents.xlsx"))
    platemap_reader = Seek::Rdf::PlatemapReader.new

    actual_sample_set = platemap_reader.read_in(csv_data)

    assert_equal(expected_sample_set, actual_sample_set)
  end

  # test "convert samples to rdf" do
  # See "to rdf platemap spreadsheet" in data_file_test.rb
  # end

  test "is platemap file" do
    csv_data = spreadsheet_to_csv(open("#{Rails.root}/test/fixtures/files/rdf/GALgenes_contents.xlsx"))
    platemap_reader = Seek::Rdf::PlatemapReader.new
    actual = platemap_reader.is_platemap_file? csv_data
    assert(actual==true, "Should recognise #{Rails.root}/test/fixtures/files/rdf/GALgenes_contents.xlsx as a platemap file")
  end

  test "is not platemap file" do
    csv_data = spreadsheet_to_csv(open("#{Rails.root}/test/fixtures/files/rdf/glucoseAndpH.xls"))
    platemap_reader = Seek::Rdf::PlatemapReader.new
    actual = platemap_reader.is_platemap_file? csv_data
    assert(actual==false, "Should recognise that #{Rails.root}/test/fixtures/files/rdf/glucoseAndpH.xls is not a platemap file")
  end
end
