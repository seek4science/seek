require 'test_helper'

class SpreadsheetTest < ActiveSupport::TestCase

  include SpreadsheetUtil

  fixtures :all

  test "spreadsheets are spreadsheets" do
    datafile = data_files(:downloadable_data_file)
    assert datafile.is_excel?
    assert datafile.is_extractable_spreadsheet?
  end

  test "spreadsheet is properly parsed" do
    datafile = data_files(:downloadable_data_file)

    spreadsheet = datafile.spreadsheet

    assert_equal 3, spreadsheet.sheets.size

    assert_equal 11, spreadsheet.sheets.first.columns.size

    assert_equal 3, spreadsheet.sheets.first.actual_rows.size

    assert_equal 11, spreadsheet.sheets[1].actual_rows.size

    assert_equal 4, spreadsheet.sheets[1].actual_rows.first.actual_cells.size

    assert_equal "a", spreadsheet.sheets[2].actual_rows[0].actual_cells[1].value
  end

  test "spreadsheet xml is cached" do
    datafile = data_files(:downloadable_data_file)
    Rails.cache.clear
    assert_nil Rails.cache.fetch("#{datafile.content_blob.cache_key}-ss-xml")


    #Creates spreadsheet
    assert !datafile.spreadsheet.nil?

    assert_not_nil Rails.cache.fetch("#{datafile.content_blob.cache_key}-ss-xml")
  end

  test "alphabetical and numeric column conversion" do
    assert_equal 53, from_alpha("BA")
    assert_equal "FO", to_alpha(171)
  end

end
