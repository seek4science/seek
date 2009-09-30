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
      post :create, :sop => {:data=>fixture_file_upload('files/little_file.txt'), :title=>"test"}, :sharing=>valid_sharing
    end

    assert_redirected_to sop_path(assigns(:sop))
  end

  test "should show sop" do
    s=sops(:one)
    s.save #to force versions to be created (saves writing fixtures)
    get :show, :id => s
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
    s=sops(:downloadable_sop)
    s.save! #to force versions to be created (saves writing fixtures)
    get :show, :id=>s
    assert_select "a", :text=>/Edit experimental conditions/, :count=>0
  end

  test "should be able to edit exp conditions for owners downloadable only sop" do
    login_as(:owner_of_my_first_sop)
    s=sops(:downloadable_sop)
    s.save #to force versions to be created (saves writing fixtures)
    get :show, :id=>s
    assert_select "a", :text=>/Edit experimental conditions/, :count=>1
  end

  test "should be able to edit exp conditions for editable sop" do
    s=sops(:editable_sop)
    s.save #to force versions to be created (saves writing fixtures)
    get :show, :id=>sops(:editable_sop)
    assert_select "a", :text=>/Edit experimental conditions/, :count=>1
  end

  def test_should_show_version
    s=sops(:editable_sop)
    s.save! #to force creation of initial version (fixtures don't include it)
    old_desc=s.description
    old_desc_regexp=Regexp.new(old_desc)

    #create new version
    s.description="This is now version 2"
    assert s.save_as_new_version
    s=Sop.find(s.id)
    assert_equal 2, s.versions.size
    assert_equal 2, s.version
    assert_equal 1, s.versions[0].version
    assert_equal 2, s.versions[1].version

    get :show, :id=>sops(:editable_sop)
    assert_select "p", :text=>/This is now version 2/, :count=>1
    assert_select "p", :text=>old_desc_regexp, :count=>0

    get :show, :id=>sops(:editable_sop), :version=>"2"
    assert_select "p", :text=>/This is now version 2/, :count=>1
    assert_select "p", :text=>old_desc_regexp, :count=>0

    get :show, :id=>sops(:editable_sop), :version=>"1"
    assert_select "p", :text=>/This is now version 2/, :count=>0
    assert_select "p", :text=>old_desc_regexp, :count=>1

  end

  def test_should_create_new_version
    s=sops(:editable_sop)
    s.save! #to force creation of initial version (fixtures don't include it)

    assert_difference("Sop::Version.count", 1) do
      post :new_version, :id=>s, :data=>fixture_file_upload('files/file_picture.png'), :revision_comment=>"This is a new revision"
    end

    assert_redirected_to sop_path(s)
    assert assigns(:sop)
    assert_not_nil flash[:notice]
    assert_nil flash[:error]

    
    s=Sop.find(s.id)
    assert_equal 2,s.versions.size
    assert_equal 2,s.version
    assert_equal "file_picture.png",s.original_filename
    assert_equal "file_picture.png",s.versions[1].original_filename
    assert_equal "little_file.txt",s.versions[0].original_filename
    assert_equal "This is a new revision",s.versions[1].revision_comments

  end

  def test_should_not_create_new_version_for_downloadable_only_sop
    s=sops(:downloadable_sop)
    s.save! #to force creation of initial version (fixtures don't include it)

    assert_no_difference("Sop::Version.count") do
      post :new_version, :id=>s, :data=>fixture_file_upload('files/file_picture.png'), :revision_comment=>"This is a new revision"
    end

    assert_redirected_to sops_path
    assert_not_nil flash[:error]

    s=Sop.find(s.id)
    assert_equal 1,s.versions.size
    assert_equal 1,s.version
    assert_equal "little_file.txt",s.original_filename   

  end

  def test_should_duplicate_conditions_for_new_version
    s=sops(:editable_sop)
    s.save! #v1
    condition1 = ExperimentalCondition.create(:unit => units(:gram),:measured_item => measured_items(:weight) ,
                                           :start_value => 1, :end_value => 2, :sop_id => s.id, :sop_version => s.version)
    assert_difference("Sop::Version.count", 1) do
      post :new_version, :id=>s, :data=>fixture_file_upload('files/file_picture.png'), :revision_comment=>"This is a new revision" #v2
    end
    
    assert_not_equal 0, s.find_version(1).experimental_conditions.count
    assert_not_equal 0, s.find_version(2).experimental_conditions.count
    assert_not_equal s.find_version(1).experimental_conditions, s.find_version(2).experimental_conditions    
  end
  
  def test_adding_new_conditions_to_different_versions
    s=sops(:editable_sop)
    s.save! #v1
    condition1 = ExperimentalCondition.create(:unit => units(:gram),:measured_item => measured_items(:weight) ,
                                           :start_value => 1, :end_value => 2, :sop_id => s.id, :sop_version => s.version)
    assert_difference("Sop::Version.count", 1) do                                           
      post :new_version, :id=>s, :data=>fixture_file_upload('files/file_picture.png'), :revision_comment=>"This is a new revision" #v2
    end
    
    s.find_version(2).experimental_conditions.each {|e| e.destroy}
    assert_equal condition1, s.find_version(1).experimental_conditions.first
    assert_equal 0, s.find_version(2).experimental_conditions.count

    condition2 = ExperimentalCondition.create(:unit => units(:gram),:measured_item => measured_items(:weight) ,
                                           :start_value => 1, :end_value => 2, :sop_id => s.id, :sop_version => 2)

    assert_not_equal 0, s.find_version(2).experimental_conditions.count
    assert_equal condition2, s.find_version(2).experimental_conditions.first
    assert_not_equal condition2, s.find_version(1).experimental_conditions.first
    assert_equal condition1, s.find_version(1).experimental_conditions.first
  end

  private


  def valid_sharing
    {
            :use_whitelist=>"0",
            :user_blacklist=>"0",
            :sharing_scope=>Policy::ALL_REGISTERED_USERS,
            :permissions=>{:contributor_types=>ActiveSupport::JSON.encode("Person"), :values=>ActiveSupport::JSON.encode({})}
    }
  end
end
