require 'test_helper'

class WorksheetTest < ActiveSupport::TestCase

  test 'create worksheet' do
    ws = Worksheet.new(content_blob: content_blobs(:unique_spreadsheet_blob), last_row: 20, last_column: 20)
    assert ws.save
  end
  test 'rows cannot be less than 1' do
    ws = worksheets(:worksheet_fail_rows)
    assert !ws.save
  end

  test 'columns cannot be less than 1' do
    ws = worksheets(:worksheet_fail_columns)
    assert !ws.save
  end

  test 'neither columns or rows cannot be less than 1' do
    ws = worksheets(:worksheet_fail_both)
    assert !ws.save
  end
end
