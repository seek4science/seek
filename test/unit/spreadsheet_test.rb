require 'test_helper'

class SpreadsheetTest < ActiveSupport::TestCase
  include Seek::Data::SpreadsheetExplorerRepresentation

  test 'spreadsheets are spreadsheets' do
    datafile = Factory :small_test_spreadsheet_datafile
    assert datafile.content_blob.is_excel?
    assert datafile.content_blob.is_extractable_spreadsheet?
  end

  test 'spreadsheet is properly parsed' do
    datafile = Factory :small_test_spreadsheet_datafile

    spreadsheet = datafile.spreadsheet
    min_rows = Seek::Data::SpreadsheetExplorerRepresentation::MIN_ROWS

    assert_equal 3, spreadsheet.sheets.size

    assert_equal 11, spreadsheet.sheets.first.columns.size

    assert_equal (min_rows - 10), spreadsheet.sheets.first.actual_rows.size # the first ten rows are nil

    assert_equal min_rows, spreadsheet.sheets[1].actual_rows.size

    assert_equal 4, spreadsheet.sheets[1].actual_rows.first.actual_cells.size

    assert_equal 'a', spreadsheet.sheets[2].actual_rows[0].actual_cells[1].value
  end

  test 'spreadsheet xml is cached' do
    datafile = Factory :small_test_spreadsheet_datafile
    Rails.cache.clear
    assert_nil Rails.cache.fetch("blob_ss_xml-#{datafile.content_blob.cache_key}")

    # Creates spreadsheet
    refute datafile.spreadsheet.nil?

    assert_not_nil Rails.cache.fetch("blob_ss_xml-#{datafile.content_blob.cache_key}")
  end

  test 'alphabetical and numeric column conversion' do
    assert_equal 53, from_alpha('BA')
    assert_equal 'FO', to_alpha(171)
  end
end
