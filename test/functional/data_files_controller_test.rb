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
    d = data_files(:picture)
    d.save
    get :show, :id => d
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => data_files(:picture).id
    assert_response :success
  end

  test "show should now allow factors studied edited for downloadable file" do
    login_as(:aaron)
    d = data_files(:downloadable_data_file)
    d.save
    get :show, :id=>d
    assert_select "a",:text=>/Edit factors studied/,:count=>0
  end

  test "show should allow factors studied edited for editable file" do
    login_as(:aaron)
    d=data_files(:editable_data_file)
    d.save
    get :show, :id=>d
    assert_select "a",:text=>/Edit factors studied/,:count=>1
  end
  
  test "show should allow factors studied edited owner of downloadable file" do
    login_as(:datafile_owner)
    d=data_files(:downloadable_data_file)
    d.save
    get :show, :id=>d
    assert_select "a",:text=>/Edit factors studied/,:count=>1
  end


  test "should update data file" do
    put :update, :id => data_files(:picture).id, :data_file => { }
    assert_redirected_to data_file_path(assigns(:data_file))
  end
  
  test "should_duplicate_factors_studied_for_new_version" do
    d=data_files(:editable_data_file)
    d.save! #v1
    sf = StudiedFactor.create(:unit => units(:gram),:measured_item => measured_items(:weight),
                              :start_value => 1, :end_value => 2, :data_file_id => d.id, :data_file_version => d.version)
    assert_difference("DataFile::Version.count", 1) do
      post :new_version, :id=>d, :data=>fixture_file_upload('files/file_picture.png'), :revision_comment=>"This is a new revision" #v2
    end
    
    assert_not_equal 0, d.find_version(1).studied_factors.count
    assert_not_equal 0, d.find_version(2).studied_factors.count
    assert_not_equal d.find_version(1).studied_factors, d.find_version(2).studied_factors    
  end
  
  test "adding_new_conditions_to_different_versions" do
    d=data_files(:editable_data_file)    
    sf = StudiedFactor.create(:unit => units(:gram),:measured_item => measured_items(:weight),
                              :start_value => 1, :end_value => 2, :data_file_id => d.id, :data_file_version => d.version)
    assert_difference("DataFile::Version.count", 1) do
      post :new_version, :id=>d, :data=>fixture_file_upload('files/file_picture.png'), :revision_comment=>"This is a new revision" #v2
    end
    
    d.find_version(2).studied_factors.each {|e| e.destroy}
    assert_equal sf, d.find_version(1).studied_factors.first
    assert_equal 0, d.find_version(2).studied_factors.count

    sf2 = StudiedFactor.create(:unit => units(:gram),:measured_item => measured_items(:weight),
                              :start_value => 2, :end_value => 3, :data_file_id => d.id, :data_file_version => 2)

    assert_not_equal 0, d.find_version(2).studied_factors.count
    assert_equal sf2, d.find_version(2).studied_factors.first
    assert_not_equal sf2, d.find_version(1).studied_factors.first
    assert_equal sf, d.find_version(1).studied_factors.first
  end
  
  def test_should_add_nofollow_to_links_in_show_page
    get :show, :id=> data_files(:data_file_with_links_in_description)    
    assert_select "div#description" do
      assert_select "a[rel=nofollow]"
    end
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
