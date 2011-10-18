require 'test_helper'

class CellRangeTest < ActiveSupport::TestCase
  fixtures :all
  include SpreadsheetUtil

  test "create cell range" do
      cell = CellRange.new(:worksheet => worksheets(:worksheet_1),:cell_range => "A1:B3")
      assert cell.save
  end


  #check it doesn't save, it produces only 1 error and it produces the correct error message
  test "input invalid cell range value" do
    cell = CellRange.new(:worksheet => worksheets(:worksheet_1),:cell_range => "A1:AB3")
    assert !cell.save
    res = ""
    assert cell.errors.length == 1
    cell.errors.each_full {|e| res = e}

    assert res == "One or more cells between <b>A1</b> and <b>AB3</b> are outside the worksheets range. Please select cells between <b>A1</b> and <b>J10</b>"
  end

  #check it doesn't save, it produces only 1 error and it produces the correct error message
  test "input invalid cell range format" do
    cell = CellRange.new(:worksheet => worksheets(:worksheet_1),:cell_range => "A1A2")
    assert !cell.save
    res = ""
    assert cell.errors.length == 1
    cell.errors.each_full {|e| res = e}

    assert res == "Invalid cell range entered. Must be in the format of <b>A1</b> or <b>A1:B1</b>"
  end

end
