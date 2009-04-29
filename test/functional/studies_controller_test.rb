require 'test_helper'

class StudiesControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:model_owner)
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:studies)
  end

  test "should get show" do
    get :show, :id=>studies(:metabolomics_study)
    assert_response :success
    assert_not_nil assigns(:study)
  end
end
