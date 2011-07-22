require 'test_helper'

class WorksheetTest < ActiveSupport::TestCase
  fixtures :all

  test "rows cannot be less than 1" do
    ws = worksheets(:worksheet_fail_rows)
    assert !ws.save
  end

  test "columns cannot be less than 1" do
    ws = worksheets(:worksheet_fail_columns)
    assert !ws.save
  end

  test "neither columns or rows cannot be less than 1" do
    ws = worksheets(:worksheet_fail_both)
    assert !ws.save
  end

end
