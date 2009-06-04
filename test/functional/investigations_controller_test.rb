require 'test_helper'

class InvestigationsControllerTest < ActionController::TestCase
  
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:model_owner)
  end

  test "should show index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:investigations)
  end

  test "should show item" do
    get :show, :id=>investigations(:metabolomics_investigation)
    assert_response :success
    assert_not_nil assigns(:investigation)
  end

  test "should show new" do
    get :new
    assert_response :success
    assert assigns(:investigation)
  end

  test "should show edit" do
    get :edit, :id=>investigations(:metabolomics_investigation)
    assert_response :success
    assert assigns(:investigation)
  end

  test "should update" do
    i=investigations(:metabolomics_investigation)
    put :update, :id=>i.id,:investigation=>{:title=>"test"}
    
    assert_redirected_to investigation_path(i)
    assert assigns(:investigation)
    assert_equal "test",assigns(:investigation).title
  end

end
