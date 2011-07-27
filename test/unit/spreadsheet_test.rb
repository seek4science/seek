require 'test_helper'

class SpreadsheetTest < ActiveSupport::TestCase

  include SpreadsheetUtil

  fixtures :all

  test "spreadsheets are spreadsheets" do
    datafile = data_files(:downloadable_data_file)
    assert datafile.is_spreadsheet?
  end

  test "spreadsheet is properly parsed" do
    datafile = data_files(:downloadable_data_file)
    if File.exists?(datafile.cached_spreadsheet_path)
      FileUtils.rm(datafile.cached_spreadsheet_path)
    end

    spreadsheet = datafile.spreadsheet

    assert_equal 3, spreadsheet.sheets.size

    assert_equal 6, spreadsheet.sheets.first.columns.size

    assert_equal 3, spreadsheet.sheets.first.rows.size

    assert_equal 1, spreadsheet.sheets[1].rows.size

    assert_equal 4, spreadsheet.sheets[1].rows.first.cells.size

    assert_equal "a", spreadsheet[2][0][1].value

    assert File.exists?(datafile.cached_spreadsheet_path)
  end

  test "spreadsheet xml is cached" do
    datafile = data_files(:downloadable_data_file)
    if File.exists?(datafile.cached_spreadsheet_path)
      FileUtils.rm(datafile.cached_spreadsheet_path)
    end
    assert !File.exists?(datafile.cached_spreadsheet_path)

    #Creates spreadsheet
    assert !datafile.spreadsheet.nil?

    assert File.exists?(datafile.cached_spreadsheet_path)
  end

  test "cache is being read" do
    datafile = data_files(:downloadable_data_file)
    if File.exists?(datafile.cached_spreadsheet_path)
      FileUtils.rm(datafile.cached_spreadsheet_path)
    end
    assert !File.exists?(datafile.cached_spreadsheet_path)

    #Creates spreadsheet
    assert !datafile.spreadsheet.nil?
    assert datafile.spreadsheet.sheets.first.name == "Sheet1"

    #Modify cached spreadsheet file
    new_content = File.open(datafile.cached_spreadsheet_path, "r"){|f| f.read}.gsub("Sheet1","ModifiedSheet1")
    File.open(datafile.cached_spreadsheet_path, "w"){|f| f.write(new_content)}

    assert (datafile.spreadsheet.sheets.first.name == "ModifiedSheet1")

    assert File.exists?(datafile.cached_spreadsheet_path)
  end

  test "alphabetical and numeric column conversion" do
    assert_equal 53, from_alpha("BA")
    assert_equal "FO", to_alpha(171)
  end

end
