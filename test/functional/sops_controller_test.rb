require 'test_helper'

class SopsControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases

  def setup
    login_as(:quentin)
    @object=sops(:downloadable_sop)
  end

  def test_get_xml_specific_version
    login_as(:owner_of_my_first_sop)
    get :show, :id=>sops(:downloadable_sop), :version=>2, :format=>"xml"
    perform_api_checks
    xml          =@response.body
    document     = LibXML::XML::Document.string(xml)
    version_node = document.find_first("//ns:version", "ns:http://www.sysmo-db.org/2010/xml/rest")
    assert_not_nil version_node
    assert_equal "2", version_node.content
    content_blob_node = document.find_first("//ns:blob", "ns:http://www.sysmo-db.org/2010/xml/rest")
    assert_not_nil content_blob_node
    md5sum=content_blob_node.find_first("//ns:md5sum", "ns:http://www.sysmo-db.org/2010/xml/rest").content

    #now check version 1
    get :show, :id=>sops(:downloadable_sop), :version=>1, :format=>"xml"
    perform_api_checks
    xml          =@response.body
    document     = LibXML::XML::Document.string(xml)
    version_node = document.find_first("//ns:version", "ns:http://www.sysmo-db.org/2010/xml/rest")
    assert_not_nil version_node
    assert_equal "1", version_node.content
    content_blob_node = document.find_first("//ns:blob", "ns:http://www.sysmo-db.org/2010/xml/rest")
    assert_not_nil content_blob_node
    md5sum2=content_blob_node.find_first("//ns:md5sum", "ns:http://www.sysmo-db.org/2010/xml/rest").content
    assert_not_equal md5sum, md5sum2

  end

  test "should not create sop with file url" do
    file_path=File.expand_path(__FILE__) #use the current file
    file_url ="file://"+file_path
    uri      =URI.parse(file_url)

    assert_no_difference('Sop.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :sop => {:title=>"Test", :data_url=>uri.to_s}, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash[:error]
  end

  def test_title
    get :index
    assert_select "title", :text=>/The Sysmo SEEK SOPs.*/, :count=>1
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
    assert_select "h1", :text=>"New SOP"
  end

  test "should correctly handle bad data url" do
    sop={:title=>"Test", :data_url=>"http:/sdfsdfds.com/sdf.png"}
    assert_no_difference('Sop.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :sop => sop, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash.now[:error]

    #not even a valid url
    sop={:title=>"Test", :data_url=>"s  df::sd:dfds.com/sdf.png"}
    assert_no_difference('Sop.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :sop => sop, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash.now[:error]
  end

  test "should not create invalid sop" do
    sop={:title=>"Test"}
    assert_no_difference('Sop.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :sop => sop, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash.now[:error]
  end

  test "should create sop" do
    assert_difference('Sop.count') do
      assert_difference('ContentBlob.count') do
        post :create, :sop => valid_sop, :sharing=>valid_sharing
      end
    end

    assert_redirected_to sop_path(assigns(:sop))
    assert_equal users(:quentin), assigns(:sop).contributor

    assert assigns(:sop).content_blob.url.blank?
    assert !assigns(:sop).content_blob.data_io_object.read.nil?
    assert assigns(:sop).content_blob.file_exists?
    assert_equal "file_picture.png", assigns(:sop).original_filename
  end

  def test_missing_sharing_should_default_to_private
    assert_difference('Sop.count') do
      assert_difference('ContentBlob.count') do
        post :create, :sop => valid_sop
      end
    end
    assert_redirected_to sop_path(assigns(:sop))
    assert_equal users(:quentin), assigns(:sop).contributor
    assert assigns(:sop)

    sop            =assigns(:sop)
    private_policy = policies(:private_policy_for_asset_of_my_first_sop)
    assert_equal private_policy.sharing_scope, sop.policy.sharing_scope
    assert_equal private_policy.access_type, sop.policy.access_type
    assert_equal private_policy.use_whitelist, sop.policy.use_whitelist
    assert_equal private_policy.use_blacklist, sop.policy.use_blacklist
    assert_equal false, sop.policy.use_custom_sharing
    assert sop.policy.permissions.empty?

    #check it doesn't create an error when retreiving the index
    get :index
    assert_response :success
  end

  test "should create sop with url" do
    assert_difference('Sop.count') do
      assert_difference('ContentBlob.count') do
        post :create, :sop => valid_sop_with_url, :sharing=>valid_sharing
      end
    end
    assert_redirected_to sop_path(assigns(:sop))
    assert_equal users(:quentin), assigns(:sop).contributor
    assert !assigns(:sop).content_blob.url.blank?
    assert assigns(:sop).content_blob.data_io_object.nil?
    assert !assigns(:sop).content_blob.file_exists?
    assert_equal "sysmo-db-logo-grad2.png", assigns(:sop).original_filename
    assert_equal "image/png", assigns(:sop).content_type
  end

  test "should create sop and store with url and store flag" do
    sop_details             =valid_sop_with_url
    sop_details[:local_copy]="1"
    assert_difference('Sop.count') do
      assert_difference('ContentBlob.count') do
        post :create, :sop => sop_details, :sharing=>valid_sharing
      end
    end
    assert_redirected_to sop_path(assigns(:sop))
    assert_equal users(:quentin), assigns(:sop).contributor
    assert !assigns(:sop).content_blob.url.blank?
    assert !assigns(:sop).content_blob.data_io_object.read.nil?
    assert assigns(:sop).content_blob.file_exists?
    assert_equal "sysmo-db-logo-grad2.png", assigns(:sop).original_filename
    assert_equal "image/png", assigns(:sop).content_type
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
    assert_select "h1", :text=>/Editing SOP/
  end

  test "publications excluded in form for sops" do
    login_as(:owner_of_my_first_sop)
    get :edit, :id => sops(:my_first_sop)
    assert_response :success
    assert_select "div#publications_fold_content", false

    get :new
    assert_response :success
    assert_select "div#publications_fold_content", false
  end

  test "should update sop" do
    login_as(:owner_of_my_first_sop)
    put :update, :id => sops(:my_first_sop).id, :sop => {:title=>"Test2"}, :sharing=>valid_sharing
    assert_redirected_to sop_path(assigns(:sop))
  end

  test "should destroy sop" do
    login_as(:owner_of_my_first_sop)
    assert_difference('Sop.count', -1) do
      assert_no_difference("ContentBlob.count") do
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

  def test_should_be_able_to_edit_exp_conditions_for_owners_downloadable_only_sop
    login_as(:owner_of_my_first_sop)
    s=sops(:downloadable_sop)

    get :show, :id=>s
    assert_select "a", :text=>/Edit experimental conditions/, :count=>1
  end

  def test_should_be_able_to_edit_exp_conditions_for_editable_sop
    s=sops(:editable_sop)

    get :show, :id=>sops(:editable_sop)
    assert_select "a", :text=>/Edit experimental conditions/, :count=>1
  end

  def test_should_show_version
    s              =sops(:editable_sop)
    old_desc       =s.description
    old_desc_regexp=Regexp.new(old_desc)

    #create new version
    s.description  ="This is now version 2"
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
      post :new_version, :id=>s, :sop=>{:data=>fixture_file_upload('files/file_picture.png')}, :revision_comment=>"This is a new revision"
    end

    assert_redirected_to sop_path(s)
    assert assigns(:sop)
    assert_not_nil flash[:notice]
    assert_nil flash[:error]

    s=Sop.find(s.id)
    assert_equal 2, s.versions.size
    assert_equal 2, s.version
    assert_equal "file_picture.png", s.original_filename
    assert_equal "file_picture.png", s.versions[1].original_filename
    assert_equal "little_file.txt", s.versions[0].original_filename
    assert_equal "This is a new revision", s.versions[1].revision_comments

  end

  def test_should_not_create_new_version_for_downloadable_only_sop
    s                    =sops(:downloadable_sop)
    current_version      =s.version
    current_version_count=s.versions.size

    assert_no_difference("Sop::Version.count") do
      post :new_version, :id=>s, :data=>fixture_file_upload('files/file_picture.png'), :revision_comment=>"This is a new revision"
    end

    assert_redirected_to sops_path
    assert_not_nil flash[:error]

    s=Sop.find(s.id)
    assert_equal current_version_count, s.versions.size
    assert_equal current_version, s.version

  end

  def test_should_duplicate_conditions_for_new_version
    s          =sops(:editable_sop)
    condition1 = ExperimentalCondition.create(:unit        => units(:gram), :measured_item => measured_items(:weight),
                                              :start_value => 1, :end_value => 2, :sop_id => s.id, :sop_version => s.version)
    assert_difference("Sop::Version.count", 1) do
      post :new_version, :id=>s, :sop=>{:data=>fixture_file_upload('files/file_picture.png')}, :revision_comment=>"This is a new revision" #v2
    end

    assert_not_equal 0, s.find_version(1).experimental_conditions.count
    assert_not_equal 0, s.find_version(2).experimental_conditions.count
    assert_not_equal s.find_version(1).experimental_conditions, s.find_version(2).experimental_conditions
  end

  def test_adding_new_conditions_to_different_versions
    s          =sops(:editable_sop)
    condition1 = ExperimentalCondition.create(:unit        => units(:gram), :measured_item => measured_items(:weight),
                                              :start_value => 1, :end_value => 2, :sop_id => s.id, :sop_version => s.version)
    assert_difference("Sop::Version.count", 1) do
      post :new_version, :id=>s, :sop=>{:data=>fixture_file_upload('files/file_picture.png')}, :revision_comment=>"This is a new revision" #v2
    end

    s.find_version(2).experimental_conditions.each { |e| e.destroy }
    assert_equal condition1, s.find_version(1).experimental_conditions.first
    assert_equal 0, s.find_version(2).experimental_conditions.count

    condition2 = ExperimentalCondition.create(:unit        => units(:gram), :measured_item => measured_items(:weight),
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
    get :show, :id=>sops(:sop_with_no_contributor)
    assert_response :success
  end

  def test_can_show_edit_for_sop_with_no_contributor
    get :edit, :id=>sops(:sop_with_no_contributor)
    assert_response :success
  end

  def test_editing_doesnt_change_contributor
    login_as(:pal_user) #this user is a member of sysmo, and can edit this sop
    sop=sops(:sop_with_no_contributor)
    put :update, :id => sop, :sop => {:title=>"blah blah blah"}, :sharing=>valid_sharing
    updated_sop=assigns(:sop)
    assert_redirected_to sop_path(updated_sop)
    assert_equal "blah blah blah", updated_sop.title, "Title should have been updated"
    assert_nil updated_sop.contributor, "contributor should still be nil"
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

  test "filtering by person" do
    login_as(:owner_of_my_first_sop)
    person = people(:person_for_owner_of_my_first_sop)
    p      =projects(:sysmo_project)
    get :index, :filter=>{:person=>person.id}, :page=>"all"
    assert_response :success
    sop  = sops(:downloadable_sop)
    sop2 = sops(:sop_with_fully_public_policy)
    assert_select "div.list_items_container" do
      assert_select "a", :text=>sop.title, :count=>1
      assert_select "a", :text=>sop2.title, :count=>0
    end
  end

  test "should not be able to update sharing without manage rights" do
    login_as(:quentin)
    user = users(:quentin)
    sop   = sops(:sop_with_all_sysmo_users_policy)

    assert sop.can_edit?(user), "sop should be editable but not manageable for this test"
    assert !sop.can_manage?(user), "sop should be editable but not manageable for this test"
    assert_equal Policy::EDITING, sop.policy.access_type, "data file should have an initial policy with access type for editing"
    put :update, :id => sop, :sop => {:title=>"new title"}, :sharing=>{:use_whitelist=>"0", :user_blacklist=>"0", :sharing_scope =>Policy::ALL_SYSMO_USERS, :access_type_2=>Policy::NO_ACCESS}
    assert_redirected_to sop_path(sop)
    sop.reload

    assert_equal "new title", sop.title
    assert_equal Policy::EDITING, sop.policy.access_type, "policy should not have been updated"

  end

  test "owner should be able to update sharing" do
    login_as(:owner_of_editing_for_all_sysmo_users_policy)
    user = users(:owner_of_editing_for_all_sysmo_users_policy)
    sop   = sops(:sop_with_all_sysmo_users_policy)

    assert sop.can_edit?(user), "sop should be editable and manageable for this test"
    assert sop.can_manage?(user), "sop should be editable and manageable for this test"
    assert_equal Policy::EDITING, sop.policy.access_type, "data file should have an initial policy with access type for editing"
    put :update, :id => sop, :sop => {:title=>"new title"}, :sharing=>{:use_whitelist=>"0", :user_blacklist=>"0", :sharing_scope =>Policy::ALL_SYSMO_USERS, :access_type_2=>Policy::NO_ACCESS}
    assert_redirected_to sop_path(sop)
    sop.reload

    assert_equal "new title", sop.title
    assert_equal Policy::NO_ACCESS, sop.policy.access_type, "policy should have been updated"
  end

  test "update tags with ajax" do
    sop=sops(:my_first_sop)
    golf_tags=tags(:golf)
    user=users(:quentin)

    assert sop.tag_counts.empty?, "This sop should have no tags for the test"

    assert_difference("ActsAsTaggableOn::Tag.count") do
      xml_http_request :post, :update_tags_ajax,{:id=>sop.id,:tag_autocompleter_unrecognized_items=>["soup"],:tag_autocompleter_selected_ids=>golf_tags.id}
    end

    sop.reload
    assert_equal ["golf","soup"],sop.tag_counts.collect(&:name).sort

  end

  private

  def valid_sop_with_url
    {:title=>"Test", :data_url=>"http://www.sysmo-db.org/images/sysmo-db-logo-grad2.png"}
  end

  def valid_sop
    {:title=>"Test", :data=>fixture_file_upload('files/file_picture.png')}
  end

  def valid_sharing
    {
        :use_whitelist =>"0",
        :user_blacklist=>"0",
        :sharing_scope =>Policy::ALL_REGISTERED_USERS,
        :permissions   =>{:contributor_types=>ActiveSupport::JSON.encode("Person"), :values=>ActiveSupport::JSON.encode({})}
    }
  end
end
