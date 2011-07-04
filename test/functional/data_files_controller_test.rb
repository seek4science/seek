
require 'test_helper'
require 'libxml'
require 'webmock/test_unit'

class DataFilesControllerTest < ActionController::TestCase
  
  fixtures :all
  
  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper
  
  def setup
    login_as(:datafile_owner)
    @object=data_files(:picture)
  end
  
  def test_title
    get :index
    assert_response :success
    assert_select "title",:text=>/The Sysmo SEEK Data.*/, :count=>1
  end

  test "get XML when not logged in" do
    logout
    df = Factory(:data_file,:policy=>Factory(:public_policy, :access_type=>Policy::VISIBLE))
    get :show,:id=>df,:format=>"xml"
    perform_api_checks

  end
  
  test "should show index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:data_files)
  end

  test 'should show index for non-project member, non-login user' do
    login_as(:registered_user_with_no_projects)
    get :index
    assert_response :success
    assert_not_nil assigns(:data_files)

    logout
    get :index
    assert_response :success
    assert_not_nil assigns(:data_files)
  end

  test 'shouldnt show upload button for non-project member and non-login user' do
    login_as(:registered_user_with_no_projects)
    get :index
    assert_response :success
    assert_not_nil assigns(:data_files)
    assert_select "a",:text=>/Upload a datafile/,:count=>0

    logout
    get :index
    assert_response :success
    assert_not_nil assigns(:data_files)
    assert_select "a",:text=>/Upload a datafile/,:count=>0
  end

  test 'non-project member and non-login user can edit datafile with public policy and editable' do
    login_as(:registered_user_with_no_projects)
    data_file = Factory(:data_file, :policy => Factory(:public_policy, :access_type => Policy::EDITING))
    assert_difference('ActivityLog.count') do
      get :show, :id => data_file
    end

    assert_response :success
    put :update, :id => data_file, :data_file => {:title => 'new title'}
    assert_equal 'new title', assigns(:data_file).title

    logout
    data_file = Factory(:data_file, :policy => Factory(:public_policy, :access_type => Policy::EDITING))
    get :show, :id => data_file
    assert_response :success
    put :update, :id => data_file, :data_file => {:title => 'new title'}
    assert_equal 'new title', assigns(:data_file).title

  end

  test "associates assay" do
    login_as(:model_owner) #can edit assay
    d = data_files(:picture)
    original_assay = assays(:metabolomics_assay)
    asset_ids = original_assay.related_asset_ids 'DataFile'
    assert asset_ids.include? d.id

    new_assay=assays(:metabolomics_assay2)
    new_asset_ids = new_assay.related_asset_ids 'DataFile'
    assert !new_asset_ids.include?(d.id)
    assert_difference('ActivityLog.count') do
      put :update, :id => d, :data_file =>{}, :assay_ids=>[new_assay.id.to_s]
    end

    assert_redirected_to data_file_path(d)
    d.reload
    original_assay.reload
    new_assay.reload

    assert !original_assay.related_asset_ids('DataFile').include?(d.id)
    assert new_assay.related_asset_ids('DataFile').include?(d.id)
  end

  test "shouldn't show hidden items in index" do
    login_as(:aaron)
    get :index, :page => "all"
    assert_response :success
    assert_equal assigns(:data_files).sort_by(&:id), Authorization.authorize_collection("view", assigns(:data_files), users(:aaron)).sort_by(&:id), "data files haven't been authorized properly"
  end

  test "should get new" do
    get :new
    assert_response :success
    assert_select "h1",:text=>"New Data file"
  end
  
  test "should correctly handle 404 url" do
    mock_http
    df={:title=>"Test",:data_url=>"http://mocked404.com"}
      assert_no_difference('DataFile.count') do
        assert_no_difference('ContentBlob.count') do
          post :create, :data_file => df, :sharing=>valid_sharing
        end
      end
    end

    assert_no_difference('DataFile.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :data_file => df, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash.now[:error]
  end
  
  test "should correctly handle bad data url" do
    df={:title=>"Test",:data_url=>"http:/sdfsdfds.com/sdf.png",:project=>projects(:sysmo_project)}
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        assert_no_difference('ContentBlob.count') do
          post :create, :data_file => df, :sharing=>valid_sharing
        end
      end
    end

    assert_not_nil flash.now[:error]
  end
  
  test "should not create invalid datafile" do
    df={:title=>"Test"}
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        assert_no_difference('ContentBlob.count') do
          post :create, :data_file => df, :sharing=>valid_sharing
        end
      end
    end

    assert_not_nil flash.now[:error]
  end
  
  test "should create data file with http_url" do
    mock_http
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file => valid_data_file_with_http_url, :sharing=>valid_sharing
        end
      end
    end
    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    assert !assigns(:data_file).content_blob.file_exists?
    assert_equal "a-piccy.png", assigns(:data_file).original_filename
    assert_equal "image/png", assigns(:data_file).content_type
  end
  
  test "should create data file with ftp_url" do
    #FIXME FTP call needs mocking out
    return puts("Skipping test DataFileControllerTest 'should create data file with ftp_url'")
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file => valid_data_file_with_ftp_url, :sharing=>valid_sharing
        end
      end
    end
    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    assert !assigns(:data_file).content_blob.file_exists?
    assert_equal "robots.txt", assigns(:data_file).original_filename    
  end
  
  test "should not create data file with file url" do
    file_path=File.expand_path(__FILE__) #use the current file
    file_url="file://"+file_path
    uri=URI.parse(file_url)    
   
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        assert_no_difference('ContentBlob.count') do
          post :create, :data_file => { :title=>"Test",:data_url=>uri.to_s}, :sharing=>valid_sharing
        end
      end
    end

    assert_not_nil flash[:error]    
  end
  
  test "should create data file and store with url and store flag" do
    mock_http
    datafile_details = valid_data_file_with_http_url
    datafile_details[:local_copy]="1"

    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file => datafile_details, :sharing=>valid_sharing
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert !assigns(:data_file).content_blob.data_io_object.read.nil?
    assert assigns(:data_file).content_blob.file_exists?
    assert_equal "a-piccy.png", assigns(:data_file).original_filename
    assert_equal "image/png", assigns(:data_file).content_type
  end  
  
  test "should gracefully handle when downloading a unknown host url" do
    WebMock.allow_net_connect!
    df=data_files(:url_no_host_data_file)
    get :download,:id=>df
    assert_redirected_to data_file_path(df,:version=>df.version)
    assert_not_nil flash[:error]
  end
  
  test "should gracefully handle when downloading a url resulting in 404" do
    mock_http
    df=data_files(:url_not_found_data_file)
    get :download,:id=>df
    assert_redirected_to data_file_path(df,:version=>df.version)
    assert_not_nil flash[:error]
  end
  
  #This test is quite fragile, because it relies on an external resource
  test "should create and redirect on download for 401 url" do
    mock_http
    df = {:title=>"401",:data_url=>"http://mocked401.com",:project=>projects(:sysmo_project)}
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file => df, :sharing=>valid_sharing
        end
      end
    end

    assert_difference('DataFile.count') do
      assert_difference('ContentBlob.count') do
        post :create, :data_file => df, :sharing=>valid_sharing
      end
    end
    
    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    assert !assigns(:data_file).content_blob.file_exists?
    assert_equal "",assigns(:data_file).original_filename
    assert_equal "",assigns(:data_file).content_type
    
    get :download, :id => assigns(:data_file)
    assert_redirected_to "http://mocked401.com"
  end
  
  
  #This test is quite fragile, because it relies on an external resource
  test "should create and redirect on download for 302 url" do
    mock_http
    df = {:title=>"302",:data_url=>"http://mocked302.com",:project=>projects(:sysmo_project)}
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file => df, :sharing=>valid_sharing
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    assert !assigns(:data_file).content_blob.file_exists?
    assert_equal "",assigns(:data_file).original_filename
    assert_equal "",assigns(:data_file).content_type
    
    get :download, :id => assigns(:data_file)
    assert_redirected_to "http://mocked302.com"
  end
  
  test "should create data file" do
    login_as(:datafile_owner) #can edit assay
    assay=assays(:assay_can_edit_by_datafile_owner)

    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file => valid_data_file, :sharing=>valid_sharing, :assay_ids => [assay.id.to_s]
        end
      end
    end
    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    
    assert !assigns(:data_file).content_blob.data_io_object.read.nil?
    assert assigns(:data_file).content_blob.url.blank?
    assay.reload
    assert assay.related_asset_ids('DataFile').include? assigns(:data_file).id
  end

  test "should create data file for upload tool" do
    assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :upload_for_tool, :data_file => valid_data_file, :recipient_id => people(:quentin_person).id
        end
      end

    assert_response :success
    df = assigns(:data_file)
    df.reload
    assert_equal users(:datafile_owner), df.contributor

    assert !df.content_blob.data_io_object.read.nil?
    assert df.content_blob.url.blank?
    assert df.policy
    assert df.policy.permissions
    assert_equal df.policy.permissions.first.contributor, people(:quentin_person)
    assert df.creators
    assert_equal df.creators.first, users(:datafile_owner).person
  end
  
  def test_missing_sharing_should_default_to_private
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file => valid_data_file
        end
      end
    end
    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    assert assigns(:data_file)
    
    df=assigns(:data_file)
    private_policy = policies(:private_policy_for_asset_of_my_first_sop)
    assert_equal private_policy.sharing_scope,df.policy.sharing_scope
    assert_equal private_policy.access_type,df.policy.access_type
    assert_equal private_policy.use_whitelist,df.policy.use_whitelist
    assert_equal private_policy.use_blacklist,df.policy.use_blacklist
    assert df.policy.permissions.empty?
    
    #check it doesn't create an error when retreiving the index
    get :index
    assert_response :success    
  end
  
  test "should show data file" do
    d = data_files(:picture)
    assert_difference('ActivityLog.count') do
      get :show, :id => d
    end

    assert_response :success
  end

  test "svg handles quotes in title" do
    d = data_files(:picture)
    d.title="\"Title with quote"
    d.save!
    assert_difference('ActivityLog.count') do
      get :show, :id => d
    end

    assert_response :success
  end
  
  test "should get edit" do
    get :edit, :id => data_files(:picture)
    assert_response :success
    assert_select "h1",:text=>/Editing Data file/
    assert_select "label",:text=>/Keep this Data file private/
  end

  
  test "publications included in form for datafile" do
    
    get :edit, :id => data_files(:picture)
    assert_response :success
    assert_select "div#publications_fold_content",true
    
    get :new
    assert_response :success
    assert_select "div#publications_fold_content",true
  end
  
  test "should download" do
    assert_difference('ActivityLog.count') do
      get :download, :id => data_files(:viewable_data_file)
    end
    assert_response :success
  end
  
  test "should download from url" do
    mock_http
      get :download, :id => data_files(:url_based_data_file)
    end

    get :download, :id => data_files(:url_based_data_file)
    assert_response :success
  end
  
  test "shouldn't download" do
    login_as(:aaron)
    get :download, :id => data_files(:viewable_data_file)
    assert_redirected_to data_file_path(data_files(:viewable_data_file))
    assert flash[:error]    
  end
  
  test "should expose spreadsheet contents" do
    login_as(:model_owner)
    get :data, :id => data_files(:downloadable_data_file),:format=>"xml"
    assert_response :success
    xml=@response.body
    schema_path=File.join(RAILS_ROOT, 'public', '2010', 'xml', 'rest', 'spreadsheet.xsd')
    validate_xml_against_schema(xml,schema_path)     
  end

  test "should fetch data content as csv" do
    login_as(:model_owner)
    get :data, :id => data_files(:downloadable_data_file),:format=>"csv"
    assert_response :success
    csv=@response.body
    assert csv.include?(%!,,"fish","bottle","ggg,gg"!)

    get :data, :id => data_files(:downloadable_data_file),:format=>"csv",:trim=>true,:sheet=>"2"
    assert_response :success
    csv=@response.body
    assert csv.include?(%!"a",1.0,TRUE,,FALSE!)
  end
  
  test "should not expose non downloadable spreadsheet" do
    login_as(:model_owner)
    get :data, :id => data_files(:viewable_data_file),:format=>"xml"    
    assert_response 403
  end
  
  def test_should_not_expose_contents_for_picture
    get :data, :id => data_files(:picture)
    assert_redirected_to data_file_path(data_files(:picture))
    assert flash[:error]    
  end
  
  test "should not expose spreadsheet contents if not authorized" do
    login_as(:aaron)
    get :data, :id => data_files(:viewable_data_file)
    assert_redirected_to data_file_path(data_files(:viewable_data_file))
    assert flash[:error]    
  end
  
  def test_should_not_allow_factors_studies_edited_for_downloadable_file
    login_as(:aaron)
    d = data_files(:downloadable_data_file)
    d.save
    assert_difference('ActivityLog.count') do
      get :show, :id=>d
    end
    assert_response :success
    assert_select "a",:text=>/Edit factors studied/,:count=>0
  end
  
  def test_should_allow_factors_studies_edited_for_editable_file
    login_as(:aaron)
    d=data_files(:editable_data_file)
    d.save
    assert_difference('ActivityLog.count') do
      get :show, :id=>d
    end

    assert_select "a",:text=>/Edit factors studied/,:count=>1
  end
  
  test "show should allow factors studied edited owner of downloadable file" do
    login_as(:datafile_owner)
    d=data_files(:downloadable_data_file)
    d.save
    assert_difference('ActivityLog.count') do
      get :show, :id=>d
    end

    assert_select "a",:text=>/Edit factors studied/,:count=>1
  end
  
  test "should update data file" do
    assert_difference('ActivityLog.count') do
      put :update, :id => data_files(:picture).id, :data_file => { }
    end

    assert_redirected_to data_file_path(assigns(:data_file))
  end
  
  def test_should_duplicate_factors_studied_for_new_version
    d=data_files(:editable_data_file)
    d.save! #v1
    sf = StudiedFactor.create(:unit => units(:gram),:measured_item => measured_items(:weight),
                              :start_value => 1, :end_value => 2, :data_file_id => d.id, :data_file_version => d.version)
    assert_difference("DataFile::Version.count", 1) do
      post :new_version, :id=>d, :data_file=>{:data=>fixture_file_upload('files/file_picture.png')}, :revision_comment=>"This is a new revision" #v2
    end
    
    assert_not_equal 0, d.find_version(1).studied_factors.count
    assert_not_equal 0, d.find_version(2).studied_factors.count
    assert_not_equal d.find_version(1).studied_factors, d.find_version(2).studied_factors
    assert_equal d.find_version(1).studied_factors.count, d.find_version(2).studied_factors.count
  end
  
  test "should destroy DataFile" do
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count', -1) do
        assert_no_difference("ContentBlob.count") do
          delete :destroy, :id => data_files(:editable_data_file).id
        end
      end
    end

    assert_redirected_to data_files_path
  end
  
  test "adding_new_conditions_to_different_versions" do
    d=data_files(:editable_data_file)    
    sf = StudiedFactor.create(:unit => units(:gram),:measured_item => measured_items(:weight),
                              :start_value => 1, :end_value => 2, :data_file_id => d.id, :data_file_version => d.version)
    assert_difference("DataFile::Version.count", 1) do
      post :new_version, :id=>d, :data_file=>{:data=>fixture_file_upload('files/file_picture.png')}, :revision_comment=>"This is a new revision" #v2
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
  
  
  
  def test_update_should_not_overwrite_contributor
    login_as(:pal_user) #this user is a member of sysmo, and can edit this data file
    df=data_files(:data_file_with_no_contributor)
    put :update, :id => df, :data_file => {:title=>"blah blah blah blah"}
    updated_df=assigns(:data_file)
    assert_redirected_to data_file_path(updated_df)
    assert_equal "blah blah blah blah",updated_df.title,"Title should have been updated"
    assert_nil updated_df.contributor,"contributor should still be nil"
  end
  
  def test_show_item_attributed_to_jerm_file
    login_as(:pal_user) #this user is a member of sysmo, and can edit this data file
    df=data_files(:editable_data_file)
    jerm_file=data_files(:data_file_with_no_contributor)
    r=Relationship.new(:subject => df, :predicate => Relationship::ATTRIBUTED_TO, :object => jerm_file)
    r.save!
    df = DataFile.find(df.id)
    assert df.attributions.collect{|a| a.object}.include?(jerm_file),"The datafile should have had the jerm file added as an attribution"
    get :show,:id=>df
    assert_response :success
    assert :success
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
    person = people(:person_for_datafile_owner)
    get :index,:filter=>{:person=>person.id},:page=>"all"
    assert_response :success    
    df = data_files(:downloadable_data_file)
    df2 = data_files(:sysmo_data_file)
    assert_select "div.list_items_container" do      
      assert_select "a",:text=>df.title,:count=>1
      assert_select "a",:text=>df2.title,:count=>0
    end
  end

  test "should not be able to update sharing without manage rights" do
     login_as(:quentin)
     user = users(:quentin)
     df = data_files(:editable_data_file)

     assert df.can_edit?(user), "data file should be editable but not manageable for this test"
     assert !df.can_manage?(user), "data file should be editable but not manageable for this test"
     assert_equal Policy::EDITING,df.policy.access_type,"data file should have an initial policy with access type for editing"
     put :update, :id => df, :data_file => {:title=>"new title" },:sharing=>{:use_whitelist=>"0",:user_blacklist=>"0",:sharing_scope =>Policy::ALL_SYSMO_USERS, "access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::NO_ACCESS }
     assert_redirected_to data_file_path(df)
     df.reload

     assert_equal "new title",df.title
     assert_equal Policy::EDITING,df.policy.access_type,"policy should not have been updated"

  end

  test "fail gracefullly when trying to access a missing data file" do
    get :show,:id=>99999
    assert_redirected_to data_files_path
    assert_not_nil flash[:error]
  end

  test "owner should be able to update sharing" do
     user = users(:datafile_owner)
     df = data_files(:editable_data_file)

     assert df.can_edit?(user), "data file should be editable and manageable for this test"
     assert df.can_manage?(user), "data file should be editable and manageable for this test"
     assert_equal Policy::EDITING,df.policy.access_type,"data file should have an initial policy with access type for editing"
     assert_difference('ActivityLog.count') do
      put :update, :id => df, :data_file => {:title=>"new title" },:sharing=>{:use_whitelist=>"0",:user_blacklist=>"0",:sharing_scope =>Policy::ALL_SYSMO_USERS,"access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::NO_ACCESS }
     end

     assert_redirected_to data_file_path(df)
     df.reload

     assert_equal "new title",df.title
     assert_equal Policy::NO_ACCESS,df.policy.access_type,"policy should have been updated"
  end

  test "update with ajax only applied when viewable" do
    login_as(:aaron)
    user=users(:aaron)
    df=data_files(:downloadable_data_file)
    assert df.tag_counts.empty?,"This should have no tags for this test to work"
    golf_tags=tags(:golf)

    assert_difference("ActsAsTaggableOn::Tagging.count") do
      xml_http_request :post, :update_tags_ajax,{:id=>df.id,:tag_autocompleter_unrecognized_items=>[],:tag_autocompleter_selected_ids=>[golf_tags.id]}
    end

    df.reload

    assert_equal ["golf"],df.tag_counts.collect(&:name)

    df=data_files(:private_data_file)
    assert df.tag_counts.empty?,"This should have no tags for this test to work"

    assert !df.can_view?(user),"Aaron should not be able to view this item for this test to be valid"

    assert_no_difference("ActsAsTaggableOn::Tagging.count") do
      xml_http_request :post, :update_tags_ajax,{:id=>df.id,:tag_autocompleter_unrecognized_items=>[],:tag_autocompleter_selected_ids=>[golf_tags.id]}
    end

    df.reload

    assert df.tag_counts.empty?,"This should still have no tags"

  end

  test "update tags with ajax" do
    df=data_files(:picture)
    golf_tags=tags(:golf)

    assert df.tag_counts.empty?, "This sop should have no tags for the test"

    assert_difference("ActsAsTaggableOn::Tag.count") do
      xml_http_request :post, :update_tags_ajax,{:id=>df.id,:tag_autocompleter_unrecognized_items=>["soup"],:tag_autocompleter_selected_ids=>golf_tags.id}
    end

    df.reload
    assert_equal ["golf","soup"],df.tag_counts.collect(&:name).sort

  end

  test "correct response to unknown action" do
    df=data_files(:picture)
    assert_raises ActionController::UnknownAction do
      get :sdkfjshdfkhsdf, :id=>df
    end
  end

  test "request file button visibility when logged in and out" do
    
    df = Factory :data_file,:policy => Factory(:policy, :sharing_scope => Policy::EVERYONE, :access_type => Policy::VISIBLE)

    assert !df.can_download?, "The datafile must not be downloadable for this test to succeed"

    get :show, :id => df
    assert_response :success
    assert_select "#request_resource_button > a",:text=>/Request Data file/,:count=>1

    logout
    get :show, :id => df
    assert_response :success
    assert_select "#request_resource_button > a",:text=>/Request Data file/,:count=>0
  end

  test "should create sharing permissions 'with your project and with all SysMO members'" do
    mock_http
    login_as(:quentin)
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file => valid_data_file_with_http_url, :sharing=>{"access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::VISIBLE,:sharing_scope=>Policy::ALL_SYSMO_USERS, :your_proj_access_type => Policy::ACCESSIBLE}
        end
      end
    end


    df=assigns(:data_file)
    assert_redirected_to data_file_path(df)
    assert_equal Policy::ALL_SYSMO_USERS, df.policy.sharing_scope
    assert_equal Policy::VISIBLE, df.policy.access_type
    assert_equal df.policy.permissions.count, 1

    permission = df.policy.permissions.first
    assert_equal permission.contributor_type, 'Project'
    assert_equal permission.contributor_id, df.project_id
    assert_equal permission.policy_id, df.policy_id
    assert_equal permission.access_type, Policy::ACCESSIBLE
  end

  test "should update sharing permissions 'with your project and with all SysMO members'" do
    login_as(:datafile_owner)
    df=data_files(:editable_data_file)
    assert df.can_manage?
    assert_equal Policy::ALL_SYSMO_USERS, df.policy.sharing_scope
    assert_equal Policy::EDITING, df.policy.access_type
    assert_equal df.policy.permissions.length, 1

    permission = df.policy.permissions.first
    assert_equal permission.contributor_type, 'FavouriteGroup'
    assert_equal permission.policy_id, df.policy_id
    assert_equal permission.access_type, Policy::DETERMINED_BY_GROUP
    assert_difference('ActivityLog.count') do
      put :update, :id => df, :data_file => {}, :sharing => {"access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::ACCESSIBLE,:sharing_scope=>Policy::ALL_SYSMO_USERS, :your_proj_access_type => Policy::EDITING}
    end
    df.reload

    assert_redirected_to data_file_path(df)
    assert_equal Policy::ALL_SYSMO_USERS, df.policy.sharing_scope
    assert_equal Policy::ACCESSIBLE, df.policy.access_type
    assert_equal 1, df.policy.permissions.length

    update_permission = df.policy.permissions.first
    assert_equal update_permission.contributor_type, 'Project'
    assert_equal update_permission.contributor_id, df.project_id
    assert_equal update_permission.policy_id, df.policy_id
    assert_equal update_permission.access_type, Policy::EDITING
  end

  test "report error when file unavailable for download" do
    df = Factory :data_file, :policy=>Factory(:public_policy)
    df.content_blob.dump_data_to_file
    assert df.content_blob.file_exists?
    FileUtils.rm df.content_blob.filepath
    assert !df.content_blob.file_exists?

    get :download,:id=>df

    assert_redirected_to df
    assert flash[:error].match(/Unable to find a copy of the file for download/)
  end

  private

  def mock_http
    file="#{Rails.root}/test/fixtures/files/file_picture.png"
    stub_request(:get, "http://mockedlocation.com/a-piccy.png").to_return(:body => File.new(file), :status => 200, :headers=>{'Content-Type' => 'image/png'})
    stub_request(:head, "http://mockedlocation.com/a-piccy.png")

    stub_request(:any, "http://mocked302.com").to_return(:status=>302)
    stub_request(:any, "http://mocked401.com").to_return(:status=>401)
    stub_request(:any, "http://mocked404.com").to_return(:status=>404)
  end
  
  def valid_data_file
    { :title=>"Test",:data=>fixture_file_upload('files/file_picture.png'),:project=>projects(:sysmo_project)}
  end
  
  def valid_data_file_with_http_url
    { :title=>"Test HTTP",:data_url=>"http://mockedlocation.com/a-piccy.png",:project=>projects(:sysmo_project)}
  end
  
  def valid_data_file_with_ftp_url
      { :title=>"Test FTP",:data_url=>"ftp://ftp.mirrorservice.org/sites/amd64.debian.net/robots.txt",:project=>projects(:sysmo_project)}
  end
  
end
