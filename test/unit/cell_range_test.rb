require 'test_helper'

class CellRangeTest < ActiveSupport::TestCase
  fixtures :all

  test 'create cell range' do
    cell = CellRange.new(worksheet: worksheets(:worksheet_1), cell_range: 'A1:B3')
    assert cell.save
  end

  test 'cell range reindexing consequences' do
    # I'm not sure what reindexing_consequences is for, so its hard to write a better test.
    cell = Factory :cell_range
    assert cell.reindexing_consequences == [cell.worksheet.content_blob.asset]
  end

  # check it doesn't save, it produces only 1 error and it produces the correct error message
  test 'input invalid cell range value' do
    cell = CellRange.new(worksheet: worksheets(:worksheet_1), cell_range: 'A1:AB3')
    assert !cell.save
    res = ''
    assert cell.errors.size == 1
    cell.errors.each do |_attribute, errors_array|
      res = errors_array
    end

    assert res == 'One or more cells between <b>A1</b> and <b>AB3</b> are outside the worksheets range. Please select cells between <b>A1</b> and <b>J10</b>'
  end

  # check it doesn't save, it produces only 1 error and it produces the correct error message
  test 'input invalid cell range format' do
    cell = CellRange.new(worksheet: worksheets(:worksheet_1), cell_range: 'A1A2')
    assert !cell.save
    res = ''
    assert cell.errors.size == 1
    cell.errors.each do |_attribute, errors_array|
      res = errors_array
    end

    assert res == 'Invalid cell range entered. Must be in the format of <b>A1</b> or <b>A1:B1</b>'
  end
end
