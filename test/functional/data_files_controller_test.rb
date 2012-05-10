
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

  test "XML for data file with tags" do
    p=Factory :person
    df = Factory(:data_file,:policy=>Factory(:public_policy, :access_type=>Policy::VISIBLE))
    Factory :tag,:annotatable=>df,:source=>p,:value=>"golf"

    test_get_xml df

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

  test 'creators show in list item' do
    p1=Factory :person
    p2=Factory :person
    df=Factory(:data_file,:title=>"ZZZZZ",:creators=>[p2],:contributor=>p1.user,:policy=>Factory(:public_policy, :access_type=>Policy::VISIBLE))

    get :index,:page=>"Z"

    #check the test is behaving as expected:
    assert_equal p1.user,df.contributor
    assert df.creators.include?(p2)
    assert_select ".list_item_title a[href=?]",data_file_path(df),"ZZZZZ","the data file for this test should appear as a list item"

    #check for avatars
    assert_select ".list_item_avatar" do
      assert_select "a[href=?]",person_path(p2) do
        assert_select "img"
      end
      assert_select "a[href=?]",person_path(p1) do
        assert_select "img"
      end
    end
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
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        assert_no_difference('ContentBlob.count') do
          post :create, :data_file => df, :sharing=>valid_sharing
        end
      end
    end
      
    assert_not_nil flash.now[:error]
  end
  
  test "should correctly handle bad data url" do
    df={:title=>"Test",:data_url=>"http:/sdfsdfds.com/sdf.png",:projects=>[projects(:sysmo_project)]}
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
    df = {:title=>"401",:data_url=>"http://mocked401.com",:projects=>[projects(:sysmo_project)]}
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
    assert_redirected_to "http://mocked401.com"
  end
  
  
  #This test is quite fragile, because it relies on an external resource
  test "should create and redirect on download for 302 url" do
    mock_http
    df = {:title=>"302",:data_url=>"http://mocked302.com",:projects=>[projects(:sysmo_project)]}
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
        post :upload_for_tool, :data_file => { :title=>"Test",:data=>fixture_file_upload('files/file_picture.png'),:project_id=>projects(:sysmo_project).id}, :recipient_id => people(:quentin_person).id
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
    assert_difference('ActivityLog.count') do
      get :download, :id => data_files(:url_based_data_file)
    end
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
    assert_difference('ActivityLog.count') do
      get :show, :id=> data_files(:data_file_with_links_in_description)
    end

    assert_select "div#description" do
      assert_select "a[rel=nofollow]"
    end
  end
  
  
  
  def test_update_should_not_overwrite_contributor
    login_as(:pal_user) #this user is a member of sysmo, and can edit this data file
    df=data_files(:data_file_with_no_contributor)
    assert_difference('ActivityLog.count') do
      put :update, :id => df, :data_file => {:title=>"blah blah blah blah"}
    end

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
    assert_difference('ActivityLog.count') do
      get :show,:id=>df
    end

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
      assert_select "a",:text=>df.title,:count=>2
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
     assert_difference('ActivityLog.count') do
      put :update, :id => df, :data_file => {:title=>"new title" },:sharing=>{:use_whitelist=>"0",:user_blacklist=>"0",:sharing_scope =>Policy::ALL_SYSMO_USERS, "access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::NO_ACCESS }
     end

     assert_redirected_to data_file_path(df)
     df.reload

     assert_equal "new title",df.title
     assert_equal Policy::EDITING,df.policy.access_type,"policy should not have been updated"

  end

  test "should not be able to update sharing permission without manage rights" do
       login_as(:quentin)
       user = users(:quentin)
       df = data_files(:editable_data_file)
       assert df.can_edit?(user), "data file should be editable but not manageable for this test"
       assert !df.can_manage?(user), "data file should be editable but not manageable for this test"
       assert_equal Policy::EDITING,df.policy.access_type,"data file should have an initial policy with access type for editing"
       assert_difference('ActivityLog.count') do
        put :update, :id => df, :data_file => {:title=>"new title" },:sharing=>{:permissions =>{:contributor_types => ActiveSupport::JSON.encode('Person'), :values => ActiveSupport::JSON.encode({"Person" => {user.person.id =>  {"access_type" =>  Policy::MANAGING}}})}}
       end

       assert_redirected_to data_file_path(df)
       df.reload
       assert_equal "new title",df.title
       assert !df.can_manage?(user)
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
    p=Factory :person
    p2=Factory :person
    viewable_df=Factory :data_file,:contributor=>p2,:policy=>Factory(:publicly_viewable_policy)
    dummy_df=Factory :data_file

    login_as p.user

    assert viewable_df.can_view?(p.user)
    assert !viewable_df.can_edit?(p.user)

    golf=Factory :tag,:annotatable=>dummy_df,:source=>p2,:value=>"golf"

    xml_http_request :post, :update_annotations_ajax,{:id=>viewable_df,:tag_autocompleter_unrecognized_items=>[],:tag_autocompleter_selected_ids=>[golf.value.id]}

    viewable_df.reload

    assert_equal ["golf"],viewable_df.annotations.collect{|a| a.value.text}

    private_df=Factory :data_file,:contributor=>p2,:policy=>Factory(:private_policy)

    assert !private_df.can_view?(p.user)
    assert !private_df.can_edit?(p.user)

    xml_http_request :post, :update_annotations_ajax,{:id=>private_df,:tag_autocompleter_unrecognized_items=>[],:tag_autocompleter_selected_ids=>[golf.value.id]}

    private_df.reload
    assert private_df.annotations.empty?

  end

  test "update tags with ajax" do
    p = Factory :person

    login_as p.user

    p2 = Factory :person
    df = Factory :data_file,:contributor=>p.user

    assert df.annotations.empty?,"this data file should have no tags for the test"

    golf = Factory :tag,:annotatable=>df,:source=>p2.user,:value=>"golf"
    Factory :tag,:annotatable=>df,:source=>p2.user,:value=>"sparrow"

    df.reload

    assert_equal ["golf","sparrow"],df.annotations.collect{|a| a.value.text}.sort
    assert_equal [],df.annotations.select{|a| a.source==p.user}.collect{|a| a.value.text}.sort
    assert_equal ["golf","sparrow"],df.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

    xml_http_request :post, :update_annotations_ajax,{:id=>df,:tag_autocompleter_unrecognized_items=>["soup"],:tag_autocompleter_selected_ids=>[golf.value.id]}

    df.reload

    assert_equal ["golf","soup","sparrow"],df.annotations.collect{|a| a.value.text}.uniq.sort
    assert_equal ["golf","soup"],df.annotations.select{|a| a.source==p.user}.collect{|a| a.value.text}.sort
    assert_equal ["golf","sparrow"],df.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

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
    assert_difference('ActivityLog.count') do
      get :show, :id => df
    end

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
    assert_equal permission.contributor_id, df.project_ids.first
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
    assert_equal update_permission.contributor_id, df.project_ids.first
    assert_equal update_permission.policy_id, df.policy_id
    assert_equal update_permission.access_type, Policy::EDITING
  end


  test "can move to presentations" do
    data_file = Factory :data_file,:contributor=>User.current_user
    assert_difference("DataFile.count", -1) do
      assert_difference("Presentation.count") do
        post :convert_to_presentation, :id=>data_file
      end
    end
  end

  test "converted presentations have correct attributions" do
    data_file = Factory :data_file,:contributor=>User.current_user
    disable_authorization_checks {data_file.relationships.create :object => Factory(:data_file), :subject => data_file, :predicate => Relationship::ATTRIBUTED_TO}
    df_attributions = data_file.attributions_objects
    assert_difference("DataFile.count", -1) do
      assert_difference("Presentation.count") do
        post :convert_to_presentation, :id=>data_file.id
      end
    end

    assert_equal df_attributions, assigns(:presentation).attributions_objects
    assert !assigns(:presentation).attributions_objects.empty?
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

  test "explore latest version" do
    get :explore,:id=>data_files(:downloadable_spreadsheet_data_file)
    assert_response :success
  end

  test "explore earlier version" do
    get :explore,:id=>data_files(:downloadable_spreadsheet_data_file),:version=>1
    assert_response :success
  end

  test "gracefully handles explore with no spreadsheet" do
    df=data_files(:picture)
    get :explore,:id=>df,:version=>1
    assert_redirected_to data_file_path(df,:version=>1)
    assert flash[:error]
  end

  test "uploader can publish the item" do
    uploader = Factory(:user)
    data_file = Factory(:data_file, :contributor => uploader)
    assert_not_equal Policy::EVERYONE, data_file.policy.sharing_scope
    login_as(uploader)
    put :update, :id => data_file, :sharing => {:sharing_scope =>Policy::EVERYONE, "access_type_#{Policy::EVERYONE}".to_sym => Policy::VISIBLE}

    assert_nil flash[:error]
  end

  test "the person who has the manage right to the item, but not the uploader, CAN NOT publish the item, if the item WAS NOT published" do
    person = Factory(:person)
    policy = Factory(:policy)
    Factory(:permission, :policy => policy, :contributor => person, :access_type => Policy::MANAGING)
    data_file = Factory(:data_file, :policy => policy)
    assert_not_equal Policy::EVERYONE, data_file.policy.sharing_scope
    login_as(person.user)
    assert data_file.can_manage?
    put :update, :id => data_file, :sharing => {:sharing_scope =>Policy::EVERYONE, "access_type_#{Policy::EVERYONE}".to_sym => Policy::VISIBLE}

    assert_not_nil flash[:error]
  end

  test "the person who has the manage right to the item, but not the uploader, CAN publish the item, if the item WAS published" do
      person = Factory(:person)
      policy = Factory(:policy, :sharing_scope => Policy::EVERYONE)
      Factory(:permission, :policy => policy, :contributor => person, :access_type => Policy::MANAGING)
      data_file = Factory(:data_file, :policy => policy)
      assert_equal Policy::EVERYONE, data_file.policy.sharing_scope
      login_as(person.user)
      assert data_file.can_manage?
      put :update, :id => data_file, :sharing => {:sharing_scope =>Policy::EVERYONE, "access_type_#{Policy::EVERYONE}".to_sym => Policy::VISIBLE}

      assert_nil flash[:error]
    end

  test "should enable the policy scope 'all visitor...' when uploader edit the item" do
      uploader = Factory(:user)
      data_file = Factory(:data_file, :contributor => uploader)
      assert_not_equal Policy::EVERYONE, data_file.policy.sharing_scope
      login_as(uploader)
      get :edit, :id => data_file

      assert_select "input[type=radio][id='sharing_scope_4'][value='4'][disabled='true']", :count => 0
  end

  test "should disable the policy scope 'all visitor...' for the manager if the item was not published" do
    person = Factory(:person)
    policy = Factory(:policy)
    Factory(:permission, :policy => policy, :contributor => person, :access_type => Policy::MANAGING)
    data_file = Factory(:data_file, :policy => policy)
    assert_not_equal Policy::EVERYONE, data_file.policy.sharing_scope
    login_as(person.user)
    assert data_file.can_manage?

    get :edit, :id => data_file

      assert_select "input[type=radio][id='sharing_scope_4'][value='4'][disabled='true']"
  end

  test "should enable the policy scope 'all visitor...' for the manager if the item was published" do
    person = Factory(:person)
    policy = Factory(:policy, :sharing_scope => Policy::EVERYONE)
    Factory(:permission, :policy => policy, :contributor => person, :access_type => Policy::MANAGING)
    data_file = Factory(:data_file, :policy => policy)
    assert_equal Policy::EVERYONE, data_file.policy.sharing_scope
    login_as(person.user)
    assert data_file.can_manage?

    get :edit, :id => data_file

    assert_select "input[type=radio][id='sharing_scope_4'][value='4'][disabled='true']", :count => 0
  end

  test "should show the latest version if the params[:version] is not specified" do
    data_file=data_files(:editable_data_file)
    get :show, :id => data_file
    assert_response :success
    assert_nil flash[:error]

    logout
    published_data_file = Factory(:data_file, :policy => Factory(:public_policy))
    get :show, :id => published_data_file
    assert_response :success
    assert_nil flash[:error]
  end

  test "should show the correct version" do
    data_file=data_files(:downloadable_spreadsheet_data_file)
    get :show, :id => data_file, :version => 1
    assert_response :success
    assert_nil flash[:error]

    get :show, :id => data_file, :version => 2
    assert_response :success
    assert_nil flash[:error]
  end

  test "should show error for the incorrect version" do
    data_file=data_files(:editable_data_file)
    get :show, :id => data_file, :version => 2
    assert_redirected_to root_path
    assert_not_nil flash[:error]
  end

  test "should show error for the user who doesn't login or is not the project member, when the user specify the version and this version is not the latest version" do
    published_data_file = Factory(:data_file, :policy => Factory(:public_policy))
    published_data_file.content_blob = Factory(:content_blob)

    published_data_file.save_as_new_version
    published_data_file.reload

    logout
    get :show, :id => published_data_file, :version => 1
    assert_redirected_to root_path
    assert_not_nil flash[:error]

    flash[:error] = nil
    get :show, :id => published_data_file, :version => 2
    assert_response :success
    assert_nil flash[:error]

    login_as(Factory(:user_not_in_project))
    get :show, :id => published_data_file, :version => 1
    assert_redirected_to root_path
    assert_not_nil flash[:error]

    flash[:error] = nil
    get :show, :id => published_data_file, :version => 2
    assert_response :success
    assert_nil flash[:error]
  end

  test "should set the other creators " do
    data_file=data_files(:picture)
    assert data_file.can_manage?,"The data file must be manageable for this test to succeed"
    put :update, :id => data_file, :data_file => {:other_creators => 'marry queen'}
    data_file.reload
    assert_equal 'marry queen', data_file.other_creators
  end

  test 'should show the other creators on the data file index' do
    data_file=data_files(:picture)
    data_file.other_creators = 'another creator'
    data_file.save
    get :index

    assert_select 'p.list_item_attribute', :text => /: another creator/, :count => 1
  end

  test 'should show the other creators in -uploader and creators- box' do
    data_file=data_files(:picture)
    data_file.other_creators = 'another creator'
    data_file.save
    get :show, :id => data_file

    assert_select 'div', :text => /another creator/, :count => 1
  end

  test "should show treatments" do
    user = Factory :user
    data=File.new("#{Rails.root}/test/fixtures/files/treatments-normal-case.xls","rb").read
    df = Factory :data_file,
                 :policy=>Factory(:downloadable_public_policy),
                 :contributor=>user,
                 :content_type=>"application/excel",
                 :content_blob=>Factory(:content_blob,:data=>data)
    get :show,:id=>df
    assert_response :success
    assert_select "table#treatments" do
      assert_select "th",:text=>"pH"
      assert_select "th",:text=>"Dilution_rate"
      assert_select "td",:text=>"samplea"
      assert_select "td",:text=>"6.5"
      assert_select "tr",:count=>4
    end
  end

  test "should not show treatments if not downloadable" do
    user = Factory :user
    data=File.new("#{Rails.root}/test/fixtures/files/treatments-normal-case.xls","rb").read
    df = Factory :data_file,
                 :policy=>Factory(:publicly_viewable_policy),
                 :contributor=>user,
                 :content_type=>"application/excel",
                 :content_blob=>Factory(:content_blob,:data=>data)
    get :show,:id=>df
    assert_response :success
    assert_select "table#treatments", :count=>0
    assert_select "span#treatments",:text=>/you do not have permission to view the treatments/i
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
    { :title=>"Test",:data=>fixture_file_upload('files/file_picture.png'),:projects=>[projects(:sysmo_project)]}
  end
  
  def valid_data_file_with_http_url
    { :title=>"Test HTTP",:data_url=>"http://mockedlocation.com/a-piccy.png",:projects=>[projects(:sysmo_project)]}
  end
  
  def valid_data_file_with_ftp_url
      { :title=>"Test FTP",:data_url=>"ftp://ftp.mirrorservice.org/sites/amd64.debian.net/robots.txt",:projects=>[projects(:sysmo_project)]}
  end
  
end
