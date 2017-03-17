require 'test_helper'

class SpreadsheetAnnotationsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:datafile_owner)
  end

  test 'create new annotation' do
    assert_difference('Annotation.count', 1) do
      xhr :post, :create, { annotation_content_blob_id: content_blobs(:private_spreadsheet_blob).id,
                            annotation_sheet_id: worksheets(:private_worksheet).sheet_number,
                            annotation_cell_coverage: 'A1:B2',
                            annotation_content: 'Annotation!' }
    end

    assert_response :success

    # Check values were properly set
    a = assigns(:annotation)
    assert_equal 1, a.annotatable.start_column
    assert_equal 1, a.annotatable.start_row
    assert_equal 2, a.annotatable.end_column
    assert_equal 2, a.annotatable.end_row
    assert_equal 'Annotation!', a.value.text
  end

  test 'create blank annotation' do
    assert_no_difference('Annotation.count') do
      xhr :post, :create, { annotation_content_blob_id: content_blobs(:private_spreadsheet_blob).id,
                            annotation_sheet_id: worksheets(:private_worksheet).sheet_number,
                            annotation_cell_coverage: 'A1:B2',
                            annotation_content: '' }
    end

    assert_response :success

    assert_no_difference('Annotation.count') do
      xhr :post, :create, { annotation_content_blob_id: content_blobs(:private_spreadsheet_blob).id,
                            annotation_sheet_id: worksheets(:private_worksheet).sheet_number,
                            annotation_cell_coverage: 'A1:B2',
                            annotation_content: '   ' }
    end

    assert_response :success
  end

  test "can't create new annotation on inaccessible spreadsheet" do
    login_as(:quentin)

    assert_no_difference('Annotation.count') do
      xhr :post, :create, { annotation_content_blob_id: content_blobs(:private_spreadsheet_blob).id,
                            annotation_sheet_id: worksheets(:private_worksheet).sheet_number,
                            annotation_cell_coverage: 'A1:B2',
                            annotation_content: 'Annotation!' }
    end

    assert_response :redirect

    assert_equal flash[:error], 'You are not permitted to annotate this spreadsheet.'
  end

  test 'update an annotation' do
    xhr :put, :update, id: annotations(:annotation_1).id,
                       annotation_content: 'Updated'

    assert_response :success

    # Check content was updated, but other attributes weren't'
    assert_equal 'Updated', assigns(:annotation).value.text
    assert_equal annotations(:annotation_1).annotatable.cell_range, assigns(:annotation).annotatable.cell_range
    assert_equal annotations(:annotation_1).source, assigns(:annotation).source
  end

  test "can't update others' annotations" do
    login_as(:quentin)

    xhr :put, :update, id: annotations(:annotation_1).id,
                       annotation_content: 'Updated'

    assert_response :error

    assert assigns(:annotation).errors.full_messages.include?("You may not edit or remove other users' annotations.")

    assert_equal 'HELLO WORLD', assigns(:annotation).value.text
  end

  test 'delete an annotation' do
    assert_difference('Annotation.count', -1) do
      xhr :delete, :destroy, id: annotations(:annotation_1).id
    end

    assert_response :success
  end

  test "can't delete others' annotations" do
    login_as(:quentin)

    assert_no_difference('Annotation.count') do
      xhr :delete, :destroy, id: annotations(:annotation_1).id
    end

    assert_response :error

    assert assigns(:annotation).errors.full_messages.include?("You may not edit or remove other users' annotations.")
  end
end
