require 'test_helper'

class SopsControllerTest < ActionController::TestCase
  
  fixtures :all
  
  include AuthenticatedTestHelper
  def setup
    login_as(:quentin)
  end



  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sops)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create sop" do
    assert_difference('Sop.count') do
      post :create, :sop => {:data=>fixture_file_upload('files/little_file.txt'),:title=>"test"},:sharing=>valid_sharing
    end

    assert_redirected_to sop_path(assigns(:sop))
  end

  test "should show sop" do
    get :show, :id => sops(:one)
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => sops(:one)
    assert_response :success
  end

  test "should update sop" do
    put :update, :id => sops(:one).id, :sop => {:title=>"Test2"}, :sharing=>valid_sharing
    assert_redirected_to sop_path(assigns(:sop))
  end

  test "should destroy sop" do
    assert_difference('Sop.count', -1) do
      delete :destroy, :id => sops(:one)
    end

    assert_redirected_to sops_path
  end

  test "should not be able to edit exp conditions for downloadable only sop" do
    get :show,:id=>sops(:downloadable_sop)
    assert_select "a",:text=>/Edit experimental conditions/,:count=>0
  end

  test "should be able to edit exp conditions for owners downloadable only sop" do
    login_as(:owner_of_my_first_sop)
    get :show,:id=>sops(:downloadable_sop)
    assert_select "a",:text=>/Edit experimental conditions/,:count=>1
  end

  test "should be able to edit exp conditions for editable sop" do
    get :show,:id=>sops(:editable_sop)
    assert_select "a",:text=>/Edit experimental conditions/,:count=>1
  end

  private
 

  def valid_sharing
    {
      :use_whitelist=>"0",
      :user_blacklist=>"0",
      :sharing_scope=>Policy::ALL_REGISTERED_USERS,
      :permissions=>{:contributor_types=>ActiveSupport::JSON.encode("Person"),:values=>ActiveSupport::JSON.encode({})}
    }
  end
end
