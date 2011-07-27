require 'test_helper'

class SpreadsheetAnnotationsControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:datafile_owner)
  end


  test "create new annotation" do
    assert true
  end

  test "update an annotation" do
    assert true
  end

  test "delete an annotation" do
    assert true
  end


  test "cannot add cell range for private datafile user does not own" do
    user_logged_in = login_as(:datafile_owner)
    puts "
          content blob id = #{content_blobs(:private_spreadsheet_blob).id}
          worksheet id =    #{worksheets(:private_worksheet).id}"

    post :create, :annotation_content_blob_id => content_blobs(:private_spreadsheet_blob).id,
         :annotation_sheet_id => worksheets(:private_worksheet).id,
         :annotation_cell_coverage => "A1:B2",
         :annotation_content => "Annotation!",
         :id => user_logged_in.id

    assert_response :success
  end

  test "" do

  end
end
