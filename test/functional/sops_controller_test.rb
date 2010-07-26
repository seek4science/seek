require 'test_helper'

class SopsControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases

  def setup
    login_as(:quentin)
    @object=sops(:downloadable_sop)
  end
  
  def test_title
    get :index
    assert_select "title",:text=>/Sysmo SEEK SOPs.*/, :count=>1
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sops)
  end

  test "shouldn't show hidden items in index" do
    login_as(:aaron)
    get :index, :page => "all"
    assert_response :success
    assert_equal assigns(:sops).sort_by(&:id), Authorization.authorize_collection("view", assigns(:sops), users(:aaron)).sort_by(&:id), "sops haven't been authorized properly"
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
    login_as(:owner_of_my_first_sop)
    s=sops(:my_first_sop)
    get :show, :id => s.id
    assert_response :success
  end

  test "should get edit" do
    login_as(:owner_of_my_first_sop)
    get :edit, :id => sops(:my_first_sop)
    assert_response :success
  end

  test "should update sop" do
    login_as(:owner_of_my_first_sop)
    put :update, :id => sops(:my_first_sop).id, :sop => {:title=>"Test2"}, :sharing=>valid_sharing
    assert_redirected_to sop_path(assigns(:sop))
  end

  test "should destroy sop" do
    login_as(:owner_of_my_first_sop)
    assert_difference('Sop.count', -1) do
      assert_no_difference("ContentBlob.count","The ContentBlob for this SOP should be preserved") do
        delete :destroy, :id => sops(:my_first_sop)
      end
    end

    assert_redirected_to sops_path
  end

  test "should not be able to edit exp conditions for downloadable only sop" do
    s=sops(:downloadable_sop)
    
    get :show, :id=>s
    assert_select "a", :text=>/Edit experimental conditions/, :count=>0
  end

  test "should be able to edit exp conditions for owners downloadable only sop" do
    login_as(:owner_of_my_first_sop)
    s=sops(:downloadable_sop)

    get :show, :id=>s
    assert_select "a", :text=>/Edit experimental conditions/, :count=>1
  end

  test "should be able to edit exp conditions for editable sop" do
    s=sops(:editable_sop)
    
    get :show, :id=>sops(:editable_sop)
    assert_select "a", :text=>/Edit experimental conditions/, :count=>1
  end

  def test_should_show_version
    s=sops(:editable_sop)    
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
    condition1 = ExperimentalCondition.create(:unit => units(:gram),:measured_item => measured_items(:weight) ,
                                           :start_value => 1, :end_value => 2, :sop_id => s.id, :sop_version => s.version)
    assert_difference("Sop::Version.count", 1) do                                           
      post :new_version, :id=>s, :data=>fixture_file_upload('files/file_picture.png'), :revision_comment=>"This is a new revision" #v2
    end
    
    s.find_version(2).experimental_conditions.each {|e| e.destroy}
    assert_equal condition1, s.find_version(1).experimental_conditions.first
    assert_equal 0, s.find_version(2).experimental_conditions.count

    condition2 = ExperimentalCondition.create(:unit => units(:gram),:measured_item => measured_items(:weight) ,
                                           :start_value => 2, :end_value => 3, :sop_id => s.id, :sop_version => 2)

    assert_not_equal 0, s.find_version(2).experimental_conditions.count
    assert_equal condition2, s.find_version(2).experimental_conditions.first
    assert_not_equal condition2, s.find_version(1).experimental_conditions.first
    assert_equal condition1, s.find_version(1).experimental_conditions.first
  end
  
  def test_should_add_nofollow_to_links_in_show_page
    get :show, :id=> sops(:sop_with_links_in_description)    
    assert_select "div#description" do
      assert_select "a[rel=nofollow]"
    end
  end

  def test_can_display_sop_with_no_contributor    
    get :show,:id=>sops(:sop_with_no_contributor)
    assert_response :success
  end

  def test_can_show_edit_for_sop_with_no_contributor
    get :edit,:id=>sops(:sop_with_no_contributor)
    assert_response :success
  end

  def test_editing_doesnt_change_contributor
    login_as(:pal_user) #this user is a member of sysmo, and can edit this sop
    sop=sops(:sop_with_no_contributor)
    put :update, :id => sop, :sop => {:title=>"blah blah blah"}, :sharing=>valid_sharing
    updated_sop=assigns(:sop)
    assert_redirected_to sop_path(updated_sop)
    assert_equal "blah blah blah",updated_sop.title,"Title should have been updated"
    assert_nil updated_sop.contributor,"contributor should still be nil"
  end
  
  test "filtering by assay" do
    assay=assays(:metabolomics_assay)
    get :index, :filter => {:assay => assay.id}
    assert_response :success
  end
  
  test "filtering by study" do
    study=studies(:metabolomics_study)
    get :index, :filter => {:study => study.id}
    assert_response :success
  end
  
  test "filtering by investigation" do
    inv=investigations(:metabolomics_investigation)
    get :index, :filter => {:investigation => inv.id}
    assert_response :success
  end

  test "filtering by project" do
    project=projects(:sysmo_project)
    get :index, :filter => {:project => project.id}
    assert_response :success
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
