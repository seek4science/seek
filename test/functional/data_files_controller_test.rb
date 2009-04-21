require 'test_helper'

class DataFilesControllerTest < ActionController::TestCase
  
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:datafile_owner)
  end

  test "should show index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:data_files)
  end

  test "should get new" do
    get :new
    assert_response :success
  end
  
  test "should create data file" do
    assert_difference('DataFile.count') do
      post :create, :data_file => valid_data_file, :sharing=>valid_sharing
    end
    assert_redirected_to data_file_path(assigns(:data_file))
  end

  test "should show data file" do
    get :show, :id => data_files(:picture).id
    assert_response :success
  end

  private

  def valid_data_file
    { :title=>"Test",:data=>fixture_file_upload('files/file_picture.png')}
  end

  def valid_sharing
    {
      :use_whitelist=>"0",
      :user_blacklist=>"0",
      :sharing_scope=>Policy::ALL_REGISTERED_USERS,
      :permissions=>{:contributor_types=>ActiveSupport::JSON.encode("Person"),:values=>ActiveSupport::JSON.encode({})}
    }
  end

end
