require 'test_helper'

class AssaysControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:aaron)
  end

  test "should show index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:assays)
  end

  test "should show item" do
    get :show, :id=>assays(:metabolomics_assay)
    assert_response :success
    assert_not_nil assigns(:assay)
  end

  test "should show new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:assay)
  end

  test "should show item with no study" do
    get :show, :id=>assays(:assay_with_no_study)
    assert_response :success
    assert_not_nil assigns(:assay)
  end
end
