require 'test_helper'

class SpreadsheetTest < ActiveSupport::TestCase
  include Seek::Data::SpreadsheetExplorerRepresentation

  test 'spreadsheets are spreadsheets' do
    datafile = FactoryBot.create :small_test_spreadsheet_datafile
    assert datafile.content_blob.is_excel?
    assert datafile.content_blob.is_extractable_spreadsheet?
    assert datafile.contains_extractable_spreadsheet?
  end

  test 'xlsm are spreadsheets' do
    datafile = FactoryBot.create :xlsm_spreadsheet_datafile
    assert datafile.content_blob.is_excel?
    assert datafile.content_blob.is_extractable_spreadsheet?
    assert datafile.contains_extractable_spreadsheet?

  end

  test 'spreadsheet is properly parsed' do
    datafile = FactoryBot.create :small_test_spreadsheet_datafile

    spreadsheet = datafile.spreadsheet
    min_rows = Seek::Data::SpreadsheetExplorerRepresentation::MIN_ROWS

    assert_equal 3, spreadsheet.sheets.size

    assert_equal 11, spreadsheet.sheets.first.columns.size

    assert_equal (min_rows - 10), spreadsheet.sheets.first.actual_rows.size # the first ten rows are nil

    assert_equal min_rows, spreadsheet.sheets[1].actual_rows.size

    assert_equal 4, spreadsheet.sheets[1].actual_rows.first.actual_cells.size

    assert_equal 'a', spreadsheet.sheets[2].actual_rows[0].actual_cells[1].value
  end

  test 'csv is properly parsed' do
    datafile = FactoryBot.create :csv_spreadsheet_datafile
    assert datafile.contains_extractable_spreadsheet?

    spreadsheet = datafile.spreadsheet
    min_rows = Seek::Data::SpreadsheetExplorerRepresentation::MIN_ROWS
    min_cols = Seek::Data::SpreadsheetExplorerRepresentation::MIN_COLS

    assert_equal 1, spreadsheet.sheets.size
    sheet = spreadsheet.sheets.first
    assert_equal 'Sheet1', sheet.name
    assert_equal (1..min_cols).to_a, sheet.columns.map(&:index)
    assert_equal min_cols, sheet.last_col
    assert_equal min_rows, sheet.last_row
    assert_equal min_rows, sheet.actual_rows.size
    assert_equal %w[1 2 3 4 5], sheet[1].actual_cells.map(&:value)
    assert_equal 'default', sheet[1][1].style
    assert_nil sheet[1][1].formula
    assert_equal '11pt', spreadsheet.styles['default']['font-size']
  end

  test 'tsv is properly parsed' do
    datafile = FactoryBot.create :tsv_population_datafile
    assert datafile.contains_extractable_spreadsheet?

    sheet = datafile.spreadsheet.sheets.first
    assert_equal 10, sheet.columns.size
    assert_equal 254, sheet.last_row
    assert_equal 254, sheet.actual_rows.size
    assert_equal 'Investigation', sheet[1][1].value
    assert_equal 'Study', sheet[1][2].value
    assert_equal 'Select host and product', sheet[2][1].value
    assert_equal 'Obtain relevant data for product', sheet[3][2].value
  end

  test 'non utf-8 csv is parsed' do
    datafile = FactoryBot.create(:data_file, content_blob: FactoryBot.create(:iso_8859_1_csv_content_blob))
    sheet = datafile.spreadsheet.sheets.first
    # quoting is disabled, so the quoted "Temp, °C()" heading is split at the comma
    assert_equal ' °C()"', sheet[2][6].value
  end

  test 'csv is read from an io' do
    workbook = parse_spreadsheet_csv(StringIO.new("a\tb\n#{(1..12).to_a.join("\t")}\n"), "\t")
    sheet = workbook.sheets.first
    # the first row determines the columns, padded to the minimum
    assert_equal 10, sheet.columns.size
    assert_equal 10, sheet.last_col
    assert_equal %w[a b], sheet[1].actual_cells.map(&:value)
    assert_equal 12, sheet[2].actual_cells.size

    sheet = parse_spreadsheet_csv(StringIO.new("#{(1..12).to_a.join(',')}\n")).sheets.first
    assert_equal 12, sheet.columns.size
    assert_equal 12, sheet.last_col
  end

  test 'empty csv is parsed' do
    sheet = parse_spreadsheet_csv(StringIO.new('')).sheets.first
    assert_equal 10, sheet.columns.size
    assert_equal Seek::Data::SpreadsheetExplorerRepresentation::MIN_ROWS, sheet.last_row
  end

  test 'spreadsheet xml is cached' do
    datafile = FactoryBot.create :small_test_spreadsheet_datafile
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
