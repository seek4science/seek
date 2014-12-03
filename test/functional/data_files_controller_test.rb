
require 'test_helper'
require 'libxml'
require 'webmock/test_unit'

class DataFilesControllerTest < ActionController::TestCase
  
  fixtures :all
  
  include AuthenticatedTestHelper
  include RestTestCases
  include RdfTestCases
  include SharingFormTestHelper
  include FunctionalAuthorizationTests

  def setup
    login_as(:datafile_owner)
  end

  def rest_api_test_object
    @object=data_files(:picture)
    @object.tag_with "tag1"
    @object
  end
  
  def test_title
    get :index
    assert_response :success
    assert_select "title",:text=>/The Sysmo SEEK Data.*/, :count=>1
  end

  #because the activity logging is currently an after_filter, the AuthorizationEnforcement can silently prevent
  #the log being saved, unless it is public, since it has passed out of the around filter and User.current_user is nil
  test "download and view activity logging for private items" do
    df = Factory :data_file,:policy=>Factory(:private_policy)
    @request.session[:user_id] = df.contributor.user.id
    assert_difference("ActivityLog.count") do
      get :show,:id=>df
    end
    assert_response :success

    al = ActivityLog.last(:order=>:id)
    assert_equal "show",al.action
    assert_equal df,al.activity_loggable

    assert_difference("ActivityLog.count") do
      get :download,:id=>df
    end
    assert_response :success

    al = ActivityLog.last(:order=>:id)
    assert_equal "download",al.action
    assert_equal df,al.activity_loggable
  end

  test "correct title and text for associating an assay for new" do
    login_as(Factory(:user))
    as_virtualliver do
      get :new
      assert_response :success
      assert_select 'div.association_step p',:text=>/You may select an existing editable #{I18n.t('assays.experimental_assay')} or #{I18n.t('assays.modelling_analysis')} or create new #{I18n.t('assays.experimental_assay')} or #{I18n.t('assays.modelling_analysis')} to associate with this #{I18n.t('data_file')}./
    end
    as_not_virtualliver do
      get :new
      assert_response :success
      assert_select 'div.association_step p', :text => /You may select an existing editable #{I18n.t('assays.experimental_assay')} or #{I18n.t('assays.modelling_analysis')} to associate with this #{I18n.t('data_file')}./
    end

    assert_select 'div.foldTitle',:text=>/#{I18n.t('assays.experimental_assay').pluralize} and #{I18n.t('assays.modelling_analysis').pluralize}/
    assert_select 'div#associate_assay_fold_content p',:text=>/The following #{I18n.t('assays.experimental_assay').pluralize} and #{I18n.t('assays.modelling_analysis').pluralize} are associated with this #{I18n.t('data_file')}:/
  end

  test "download and view options for anonymous sharing" do
    login_as(Factory(:user))
    get :new
    assert_response :success
    assert_select "#simple_sharing" do
      assert_select "select#access_type_select_4" do
        assert_select "option[value=?]",1,:text=>/#{Regexp.escape(I18n.t('access.visible_downloadable'))}/i
        assert_select "option[value=?][selected='selected']",2,:text=>/#{I18n.t('access.accessible_downloadable')}/i
      end
    end
  end

  test "correct title and text for associating an assay for edit" do
    df = Factory :data_file
    login_as(df.contributor.user)
    as_virtualliver do
      get :edit, :id => df.id
      assert_response :success
      assert_select 'div.association_step p', :text => /You may select an existing editable #{I18n.t('assays.experimental_assay')} or #{I18n.t('assays.modelling_analysis')} or create new #{I18n.t('assays.experimental_assay')} or #{I18n.t('assays.modelling_analysis')} to associate with this #{I18n.t('data_file')}./
    end
    as_not_virtualliver do
      get :edit, :id => df.id
      assert_response :success
      assert_select 'div.association_step p', :text => /You may select an existing editable #{I18n.t('assays.experimental_assay')} or #{I18n.t('assays.modelling_analysis')} to associate with this #{I18n.t('data_file')}./
    end

    assert_select 'div.foldTitle', :text => /#{I18n.t('assays.experimental_assay').pluralize} and #{I18n.t('assays.modelling_analysis').pluralize}/
    assert_select 'div#associate_assay_fold_content p', :text => /The following #{I18n.t('assays.experimental_assay').pluralize} and #{I18n.t('assays.modelling_analysis').pluralize} are associated with this #{I18n.t('data_file')}:/

  end

  test "get XML when not logged in" do
    logout
    df = Factory(:data_file,:policy=>Factory(:public_policy, :access_type=>Policy::VISIBLE))
    get :show,:id=>df,:format=>"xml"
    perform_api_checks

  end

  test "data files tab should be selected" do
    as_not_virtualliver do
      get :index
      #VLN uses drop down menu, while SysMO uses two level menus
      assert_select "span#assets_menu_section" do
        assert_select "li.selected_menu" do
          assert_select "a[href=?]", data_files_path, :text => I18n.t('data_file').pluralize
        end
      end
      assert_select "ul.menutabs" do
        assert_select "li#selected_tabnav" do
          assert_select "a", :text => I18n.t("menu.assets")
        end
      end
    end


end

  test "XML for data file with tags" do
    p=Factory :person
    df = Factory(:data_file,:policy=>Factory(:public_policy, :access_type=>Policy::VISIBLE))
    Factory :tag,:annotatable=>df,:source=>p,:value=>"golf"

    test_get_rest_api_xml df

  end

  test "should include tags in XML" do
      p=Factory :person
      df = Factory(:data_file,:policy=>Factory(:public_policy, :access_type=>Policy::VISIBLE))
      Factory :tag,:annotatable=>df,:source=>p,:value=>"golf"
      Factory :tag,:annotatable=>df,:source=>p,:value=>"<fish>"
      Factory :tag,:annotatable=>df,:source=>p,:value=>"frog",:attribute_name=>"tool"
      Factory :tag,:annotatable=>df,:source=>p,:value=>"stuff",:attribute_name=>"expertise"

      test_get_rest_api_xml df

      assert_response :success
      xml = @response.body
      assert xml.include?('<tags>')
      assert xml.include?('<tag context="tag">golf')
      assert xml.include?('<tag context="tag">&lt;fish&gt;')
      assert xml.include?('<tag context="tool">frog')
      assert xml.include?('<tag context="expertise">stuff')

  end
  
  test "should show index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:data_files)
  end

  test 'should show index for non project member, should show for non login user' do
    login_as(:registered_user_with_no_projects)
    get :index
    assert_response :success

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
    end
  end

  test 'non project member and non login user cannot edit datafile with public policy and editable' do
    login_as(:registered_user_with_no_projects)
    data_file = Factory(:data_file, :policy => Factory(:public_policy, :access_type => Policy::EDITING))

    put :update, :id => data_file, :data_file => {:title => 'new title'}

    assert_response :redirect

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

  test "associate sample" do
     # associate to a new data file
     data_file_with_samples,blob = valid_data_file
     data_file_with_samples[:sample_ids] = [Factory(:sample,:title=>"newTestSample",:contributor=> User.current_user).id]
     assert_difference("DataFile.count") do
       post :create,:data_file => data_file_with_samples,:content_blob=>blob, :sharing => valid_sharing
     end

    df = assigns(:data_file)
    assert_equal "newTestSample", df.samples.first.title

    #edit associations of samples to an existing data file
    put :update,:id=> df.id, :data_file => {:sample_ids=> [Factory(:sample,:title=>"editTestSample",:contributor=> User.current_user).id]}
    df = assigns(:data_file)
    assert_equal "editTestSample", df.samples.first.title
  end


  test "shouldn't show hidden items in index" do
    login_as(:aaron)
    get :index, :page => "all"
    assert_response :success
    assert_equal assigns(:data_files).sort_by(&:id), DataFile.authorize_asset_collection(assigns(:data_files), "view", users(:aaron)).sort_by(&:id), "data files haven't been authorized properly"
  end

  test "should get new" do
    get :new
    assert_response :success
    assert_select "h1",:text=>"New #{I18n.t('data_file')}"
  end


  test "should correctly handle bad data url" do
    stub_request(:head, "http://sdfsdfds.com/sdf.png").
        to_raise(SocketError)
    df={:title=>"Test",:project_ids=>[projects(:sysmo_project).id]}
    blob={:data_url=>"http://sdfsdfds.com/sdf.png"}
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        assert_no_difference('ContentBlob.count') do
          post :create, :data_file => df,:content_blob=>blob, :sharing=>valid_sharing
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
          post :create, :data_file => df,:content_blob=>{}, :sharing=>valid_sharing
        end
      end
    end

    assert_not_nil flash.now[:error]
  end
  
  test "should create data file with http_url" do
    mock_http
    data_file,blob = valid_data_file_with_http_url

    
    assert_difference('DataFile.count') do
      assert_difference('ContentBlob.count') do
        post :create, :data_file => data_file,:content_blob=>blob, :sharing=>valid_sharing
      end
    end
      
    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    assert !assigns(:data_file).content_blob.file_exists?
    assert_equal "text/plain", assigns(:data_file).content_blob.content_type
    assert_equal "txt_test.txt", assigns(:data_file).content_blob.original_filename
  end
  


  test "should create data file with https_url" do
      mock_https
      data_file,blob = valid_data_file_with_https_url

      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file => data_file,:content_blob=>blob, :sharing=>valid_sharing
        end
      end

      assert_redirected_to data_file_path(assigns(:data_file))
      assert_equal users(:datafile_owner),assigns(:data_file).contributor
      assert !assigns(:data_file).content_blob.url.blank?
      assert assigns(:data_file).content_blob.data_io_object.nil?
      assert !assigns(:data_file).content_blob.file_exists?
      assert_equal "txt_test.txt", assigns(:data_file).content_blob.original_filename
      assert_equal "text/plain", assigns(:data_file).content_blob.content_type
  end
  
  test "should not create data file with file url" do
    file_path=File.expand_path(__FILE__) #use the current file
    file_url="file://"+file_path
    uri=URI.parse(file_url)    
   
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        assert_no_difference('ContentBlob.count') do
          post :create, :data_file => { :title=>"Test"},:content_blob=>{:data_url=>uri.to_s}, :sharing=>valid_sharing
        end
      end
    end

    assert_not_nil flash[:error]    
  end
  
  test "should create data file and store with url" do
    mock_http
    data,blob = valid_data_file_with_http_url
    blob[:make_local_copy]="1"

    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file=>data,:content_blob=>blob,
               :sharing=>valid_sharing
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert !assigns(:data_file).content_blob.data_io_object.read.nil?
    assert assigns(:data_file).content_blob.file_exists?
    assert_equal "txt_test.txt", assigns(:data_file).content_blob.original_filename
    assert_equal "text/plain", assigns(:data_file).content_blob.content_type
  end

  test "should create data file and store with url even with http protocol missing" do
    mock_http
    data,blob = valid_data_file_with_http_url
    blob[:data_url]="mockedlocation.com/txt_test.txt"
    blob[:make_local_copy]="1"

    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file=>data,:content_blob=>blob,
               :sharing=>valid_sharing
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert !assigns(:data_file).content_blob.data_io_object.read.nil?
    assert assigns(:data_file).content_blob.file_exists?
    assert_equal "txt_test.txt", assigns(:data_file).content_blob.original_filename
    assert_equal "text/plain", assigns(:data_file).content_blob.content_type
  end

  test "should correctly handle 404 url" do
    mock_http
    df={:title=>"Test"}
    blob={:data_url=>"http://mocked404.com"}
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        assert_no_difference('ContentBlob.count') do
          post :create, :data_file => df,:content_blob=>blob, :sharing=>valid_sharing
        end
      end
    end

    assert_not_nil flash.now[:error]
  end

  test "should create data file" do
    login_as(:datafile_owner) #can edit assay
    assay=assays(:assay_can_edit_by_datafile_owner)
    data_file,blob = valid_data_file
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('DataFile::Version.count') do
          assert_difference('ContentBlob.count') do
            post :create, :data_file => data_file,:content_blob=>blob, :sharing=>valid_sharing, :assay_ids => [assay.id.to_s]
          end
        end

      end
    end
    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    
    assert !assigns(:data_file).content_blob.data_io_object.read.nil?
    assert assigns(:data_file).content_blob.url.blank?
    assert_equal 1,assigns(:data_file).version
    assert_not_nil assigns(:data_file).latest_version
    assay.reload
    assert assay.related_asset_ids('DataFile').include? assigns(:data_file).id
  end

  test "upload_for_tool inacessible with normal login" do
    post :upload_for_tool, :data_file => { :title=>"Test",:data=>fixture_file_upload('files/file_picture.png'),:project_id=>projects(:sysmo_project).id}, :recipient_id => people(:quentin_person).id
    assert_redirected_to root_url
  end

  test "upload_from_email inacessible with normal login" do
    post :upload_from_email, :data_file => { :title=>"Test",:data=>fixture_file_upload('files/file_picture.png'),:project_id=>projects(:sysmo_project).id}, :recipient_ids => [people(:quentin_person).id], :cc_ids => []
    assert_redirected_to root_url
  end

  test "should create data file for upload tool" do
    assert_difference('DataFile.count') do
      assert_difference('ContentBlob.count') do
        session[:xml_login] = true
        post :upload_for_tool, :data_file => { :title=>"Test",:project_id=>projects(:sysmo_project).id},
             :content_blob=>{:data=>file_for_upload},
             :recipient_id => people(:quentin_person).id
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

  test "should create data file from email tool" do
    old_admin_impersonation = Seek::Config.admin_impersonation_enabled
    Seek::Config.admin_impersonation_enabled = true
    login_as Factory(:admin).user
    assert_difference('DataFile.count') do
      assert_difference('ContentBlob.count') do
        session[:xml_login] = true
        post :upload_from_email, :data_file => { :title=>"Test",:project_ids=>[projects(:sysmo_project).id]},
             :content_blob=>{:data=>file_for_upload},:recipient_ids => [people(:quentin_person).id], :sender_id => users(:datafile_owner).person_id
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
    Seek::Config.admin_impersonation_enabled = old_admin_impersonation
  end

  def test_missing_sharing_should_default_to_private
    data_file,blob = valid_data_file
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file => data_file,:content_blob=>blob
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

  def test_missing_sharing_should_default_to_blank_for_vln
    data_file,blob = valid_data_file
    with_config_value "is_virtualliver",true do
      assert_no_difference('ActivityLog.count') do
        assert_no_difference('DataFile.count') do
          assert_no_difference('ContentBlob.count') do
            post :create, :data_file => data_file,:content_blob=>blob
          end
        end
      end

      df=assigns(:data_file)
      assert !df.valid?
      assert !df.policy.valid?
      assert_blank df.policy.sharing_scope
      assert_blank df.policy.access_type
      assert_blank df.policy.permissions
    end
  end
  
  test "should show data file" do
    d = Factory :rightfield_datafile,:policy=>Factory(:public_policy)
    assert_difference('ActivityLog.count') do
      get :show, :id => d
    end
    assert_response :success

    assert_select "div.box_about_actor" do
      assert_select "p > b",:text=>/Filename:/
      assert_select "p",:text=>/rightfield\.xls/
      assert_select "p > b",:text=>/Format:/
      assert_select "p",:text=>/Spreadsheet/
      assert_select "p > b",:text=>/Size:/
      assert_select "p",:text=>/9 KB/
    end

  end

  test "should add link to a webpage" do
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html","http://webpage.com",{'Content-Type' => 'text/html'}

    data_file = { :title=>"Test HTTP",:project_ids=>[projects(:sysmo_project).id]}
    blob = {:data_url=>"http://webpage.com"}

    assert_difference('DataFile.count') do
      assert_difference('ContentBlob.count') do
        post :create, :data_file => data_file,:content_blob=>blob, :sharing=>valid_sharing
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    assert !assigns(:data_file).content_blob.file_exists?
    assert_equal "", assigns(:data_file).content_blob.original_filename
    assert assigns(:data_file).content_blob.is_webpage?
    assert_equal "http://webpage.com", assigns(:data_file).content_blob.url
    assert_equal "text/html", assigns(:data_file).content_blob.content_type
  end

  test "should add link to a webpage with http protocol missing" do
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html","http://webpage.com",{'Content-Type' => 'text/html'}

    data_file = { :title=>"Test HTTP",:project_ids=>[projects(:sysmo_project).id]}
    blob = {:data_url=>"webpage.com"}

    assert_difference('DataFile.count') do
      assert_difference('ContentBlob.count') do
        post :create, :data_file => data_file,:content_blob=>blob, :sharing=>valid_sharing
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    assert !assigns(:data_file).content_blob.file_exists?
    assert_equal "", assigns(:data_file).content_blob.original_filename
    assert assigns(:data_file).content_blob.is_webpage?
    assert_equal "http://webpage.com", assigns(:data_file).content_blob.url
    assert_equal "text/html", assigns(:data_file).content_blob.content_type
  end

  test "should add link to a webpage from windows browser" do
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html","http://webpage.com",{'Content-Type' => 'text/html'}
    data_file = { :title=>"Test HTTP",:project_ids=>[projects(:sysmo_project).id]}
    blob = {:data_url=>"http://webpage.com"}

    assert_difference('DataFile.count') do
      assert_difference('ContentBlob.count') do
        @request.env['HTTP_USER_AGENT']="Windows"
        post :create, :data_file => data_file,:content_blob=>blob, :sharing=>valid_sharing
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    assert !assigns(:data_file).content_blob.file_exists?
    assert_equal "", assigns(:data_file).content_blob.original_filename
    assert assigns(:data_file).content_blob.is_webpage?
    assert_equal "http://webpage.com", assigns(:data_file).content_blob.url
    assert_equal "text/html", assigns(:data_file).content_blob.content_type
  end

  test "should show wepage as a link" do
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html","http://webpage.com",{'Content-Type' => 'text/html'}

    df = Factory :data_file,:content_blob=>Factory(:content_blob,:url=>"http://webpage.com")

    assert df.content_blob.is_webpage?
    login_as(df.contributor.user)
    get :show,:id=>df
    assert_response :success

    assert_select "div.box_about_actor" do
      assert_select "p > b",:text=>/Link:/
      assert_select "a[href=?][target=_blank]","http://webpage.com",:text=>"http://webpage.com"
      assert_select "p > b",:text=>/Format:/,:count=>0
      assert_select "p > b",:text=>/Size:/,:count=>0
    end
  end

  test "should not show website link for viewable but inaccessible data but should show request button" do
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html","http://webpage.com",{'Content-Type' => 'text/html'}
    df = Factory :data_file,:content_blob=>Factory(:content_blob,:url=>"http://webpage.com"),:policy=>Factory(:all_sysmo_viewable_policy)
    user = Factory :user
    assert df.can_view?(user)
    assert !df.can_download?(user)
    login_as(user)
    get :show,:id=>df
    assert_response :success

    assert_select "div.box_about_actor" do
      assert_select "p > b",:text=>/Link/,:count=>0
      assert_select "a[href=?][target=_blank]","http://webpage.com",:text=>"http://webpage.com",:count=>0
    end

    assert_select "ul.sectionIcons > li > span.icon" do
      assert_select "a",:text=>/Request/,:count=>1
    end

  end



  test "svg handles quotes in title" do
    d = Factory :rightfield_datafile, :title=>"\"Title with quote",:policy=>Factory(:public_policy)

    assert_difference('ActivityLog.count') do
      get :show, :id => d
    end

    assert_response :success
  end
  
  test "should get edit" do
    get :edit, :id => data_files(:picture)
    assert_response :success
    assert_select "h1",:text=>/Editing #{I18n.t('data_file')}/
    assert_select "label",:text=>/Keep this #{I18n.t('data_file')} private/i
  end

  
  test "publications included in form for datafile" do
    
    get :edit, :id => data_files(:picture)
    assert_response :success
    assert_select "div#publications_fold_content",true
    
    get :new
    assert_response :success
    assert_select "div#publications_fold_content",true
  end

  test "dont show download button or count for website/external_link data file" do
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html","http://webpage.com",{'Content-Type' => 'text/html'}
    df = Factory :data_file,:content_blob=>Factory(:content_blob,:url=>"http://webpage.com", :external_link => true)
    assert df.content_blob.is_webpage?
    login_as(df.contributor.user)
    assert df.can_download?(df.contributor.user)
    get :show,:id=>df
    assert_response :success
    assert_select "ul.sectionIcons > li > span.icon" do
      assert_select "a[href=?]",download_data_file_path(df,:version=>df.version),:count=>0
      assert_select "a",:text=>/Download/,:count=>0
      assert_select "a",:text=>/Request/,:count=>0
    end

    assert_select "div.contribution_section_box > div.usage_info" do
      assert_select "b",:text=>/Downloads/,:count=>0
    end
  end

  test "show download button for non website data file" do
    df = Factory :data_file
    login_as(df.contributor.user)
    get :show,:id=>df
    assert_response :success
    assert_select "ul.sectionIcons > li > span.icon" do
      assert_select "a[href=?]",download_data_file_path(df,:version=>df.version),:count=>1
      assert_select "a",:text=>/Download #{I18n.t('data_file')}/,:count=>1
    end

    assert_select "div.contribution_section_box > div.usage_info" do
      assert_select "b",:text=>/Downloads/,:count=>1
    end

  end



  test "should download datafile from standard route" do
    df = Factory :rightfield_datafile, :policy=>Factory(:public_policy)
    login_as(df.contributor.user)
    assert_difference("ActivityLog.count") do
      get :download, :id=>df.id
    end
    assert_response :success
    al=ActivityLog.last
    assert_equal "download",al.action
    assert_equal df,al.activity_loggable
    assert_equal "attachment; filename=\"rightfield.xls\"",@response.header['Content-Disposition']
    assert_equal "application/excel",@response.header['Content-Type']
    assert_equal "9216",@response.header['Content-Length']
  end

  test "should download" do
    assert_difference('ActivityLog.count') do
      get :download, :id => Factory(:small_test_spreadsheet_datafile,:policy=>Factory(:public_policy), :contributor=>User.current_user).id
    end
    assert_response :success
    assert_equal "attachment; filename=\"small-test-spreadsheet.xls\"",@response.header['Content-Disposition']
    assert_equal "application/excel",@response.header['Content-Type']
    assert_equal "7168",@response.header['Content-Length']
  end

  test "should download from url" do
    mock_http
    assert_difference('ActivityLog.count') do
      get :download, :id => data_files(:url_based_data_file)
    end
    assert_response :success
  end

  test "should gracefully handle when downloading a unknown host url" do
    stub_request(:any, "http://sdkfhsdfkhskfj.com/pic.png").to_raise(SocketError)
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


  test "should create and redirect on download for 401 url" do
    mock_http
    df = {:title=>"401",:project_ids=>[projects(:sysmo_project).id]}
    blob = {:data_url=>"http://mocked401.com"}
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file => df,:content_blob=>blob, :sharing=>valid_sharing
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    assert !assigns(:data_file).content_blob.file_exists?
    assert_equal "",assigns(:data_file).content_blob.original_filename
    assert_equal "",assigns(:data_file).content_blob.content_type

    get :download, :id => assigns(:data_file)
    assert_redirected_to "http://mocked401.com"
  end

  test "should create and redirect on download for 403 url" do
    mock_http
    df = {:title=>"401",:project_ids=>[projects(:sysmo_project).id]}
    blob = {:data_url=>"http://mocked403.com"}
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file => df,:content_blob=>blob, :sharing=>valid_sharing
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    assert !assigns(:data_file).content_blob.file_exists?
    assert_equal "",assigns(:data_file).content_blob.original_filename
    assert_equal "",assigns(:data_file).content_blob.content_type

    get :download, :id => assigns(:data_file)
    assert_redirected_to "http://mocked403.com"
  end



  test "should create and redirect on download for 302 url" do
    mock_http
    df = {:title=>"302",:project_ids=>[projects(:sysmo_project).id]}
    blob = {:data_url=>"http://mocked302.com", :make_local_copy => "0"}
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file => df,:content_blob=>blob, :sharing=>valid_sharing
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    assert !assigns(:data_file).content_blob.file_exists?
    assert_equal "",assigns(:data_file).content_blob.original_filename
    assert_equal "text/html",assigns(:data_file).content_blob.content_type

    get :download, :id => assigns(:data_file)
    assert_redirected_to "http://mocked302.com"
  end

  test "should create and redirect on download for 301 url" do
    mock_http
    df = {:title=>"301",:project_ids=>[projects(:sysmo_project).id]}
    blob = {:data_url=>"http://mocked301.com", :make_local_copy => "0"}
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file => df,:content_blob=>blob, :sharing=>valid_sharing
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner),assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    assert !assigns(:data_file).content_blob.file_exists?
    assert_equal "",assigns(:data_file).content_blob.original_filename
    assert_equal "text/html",assigns(:data_file).content_blob.content_type

    get :download, :id => assigns(:data_file)
    assert_redirected_to "http://mocked301.com"
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

  test "should handle inline download when specify the inline disposition" do
    data=File.new("#{Rails.root}/test/fixtures/files/file_picture.png","rb").read
    df = Factory :data_file,
                 :content_blob => Factory(:content_blob, :data => data, :content_type=>"images/png"),
                 :policy => Factory(:downloadable_public_policy)

    get :download, :id => df, :disposition => 'inline'
    assert_response :success
    assert @response.header['Content-Disposition'].include?('inline')
  end

  test "should handle normal attachment download" do
    data=File.new("#{Rails.root}/test/fixtures/files/file_picture.png","rb").read
    df = Factory :data_file,
                 :content_blob => Factory(:content_blob, :data => data, :content_type=>"images/png"),
                 :policy => Factory(:downloadable_public_policy)

    get :download, :id => df
    assert_response :success
    assert @response.header['Content-Disposition'].include?('attachment')
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
    schema_path=File.join(Rails.root, 'public', '2010', 'xml', 'rest', 'spreadsheet.xsd')
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
    assert csv.include?(%!"a",1,TRUE,,FALSE!)
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
    StudiedFactor.destroy_all
    d= Factory(:data_file,:contributor=>User.current_user)
    d.save! #v1
    sf = StudiedFactor.create(:unit_id => units(:gram).id,:measured_item => measured_items(:weight),
                              :start_value => 1, :end_value => 2, :data_file_id => d.id, :data_file_version => d.version)

    d.reload
    assert_equal 1,d.studied_factors.count

    assert d.can_manage?
    assert_difference("DataFile::Version.count", 1) do
      assert_difference("StudiedFactor.count",1) do
        post :new_version, :id=>d.id, :data_file=>{},:content_blob=>{:data=>file_for_upload}, :revision_comment=>"This is a new revision" #v2
      end
    end

    assert_redirected_to d
    d.reload

    assert_equal 1, d.find_version(1).studied_factors.count
    assert_equal 1, d.find_version(2).studied_factors.count
    assert_not_equal d.find_version(1).studied_factors, d.find_version(2).studied_factors

  end
  
  test "should destroy DataFile" do
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count',  -1) do
        assert_no_difference("ContentBlob.count") do
          delete :destroy, :id => data_files(:editable_data_file).id
        end
      end
    end

    assert_redirected_to data_files_path
  end

  test "should be possible to delete one version of data file" do
      Seek::Config.delete_asset_version_enabled = true
      #upload a data file
      df = Factory :data_file, :contributor => User.current_user
      #upload new version 1 of the data file
      post :new_version, :id=>df, :data_file=>{},:content_blob=>{:data=>file_for_upload}, :revision_comment=>"This is a new revision 1"
      #upload new version 2 of the data file
      post :new_version, :id=>df, :data_file=>{},:content_blob=>{:data=>file_for_upload}, :revision_comment=>"This is a new revision 2"

      df.reload
      assert_equal 3, df.versions.length

      # the latest version is 3
      assert_equal 3, df.version

      assert_difference("df.versions.length",  -1) do
        put :destroy_version, :id=>df, :version => 3
        df.reload
      end
      # the latest version becomes 2
      assert_equal 2, df.version
      assert_redirected_to data_file_path(df)
  end

  test "adding_new_conditions_to_different_versions" do
    d=data_files(:editable_data_file)    
    sf = StudiedFactor.create(:unit_id => units(:gram).id,:measured_item => measured_items(:weight),
                              :start_value => 1, :end_value => 2, :data_file_id => d.id, :data_file_version => d.version)
    assert_difference("DataFile::Version.count", 1) do
      assert_difference("StudiedFactor.count",1) do
        post :new_version, :id=>d, :data_file=>{},:content_blob=>{:data=>file_for_upload}, :revision_comment=>"This is a new revision" #v2
      end
    end
    
    d.find_version(2).studied_factors.each {|e| e.destroy}
    assert_equal sf, d.find_version(1).studied_factors.first
    assert_equal 0, d.find_version(2).studied_factors.count
    
    sf2 = StudiedFactor.create(:unit_id => units(:gram).id,:measured_item => measured_items(:weight),
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
    login_as(:datafile_owner) #this user is a member of sysmo, and can edit this data file
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
    login_as(:datafile_owner) #this user is a member of sysmo, and can edit this data file
    df=data_files(:editable_data_file)
    jerm_file=data_files(:data_file_with_no_contributor)
    r=Relationship.new(:subject => df, :predicate => Relationship::ATTRIBUTED_TO, :other_object => jerm_file)
    r.save!
    df = DataFile.find(df.id)
    assert df.attributions.collect{|a| a.other_object}.include?(jerm_file),"The datafile should have had the jerm file added as an attribution"
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
    assert_response :not_found
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
    assert_raises ActionController::RoutingError do
      get :sdkfjshdfkhsdf, :id=>df
    end
  end

  test "request file button visibility when logged in and out" do
    
    df = Factory :data_file, :policy => Factory(:policy, :sharing_scope => Policy::EVERYONE, :access_type => Policy::VISIBLE)

    assert !df.can_download?, "The datafile must not be downloadable for this test to succeed"
    assert_difference('ActivityLog.count') do
      get :show, :id => df
    end

    assert_response :success
    assert_select "#request_resource_button > a",:text=>/Request #{I18n.t('data_file')}/,:count=>1

    logout
    get :show, :id => df
    assert_response :success
    assert_select "#request_resource_button > a",:text=>/Request #{I18n.t('data_file')}/,:count=>0
  end

  test "should create sharing permissions 'with your project and with all SysMO members'" do
    mock_http
    data_file,blob = valid_data_file_with_http_url
    login_as(:quentin)
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, :data_file =>data_file,:content_blob=>blob, :sharing=>{"access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::VISIBLE,:sharing_scope=>Policy::ALL_SYSMO_USERS, :your_proj_access_type => Policy::ACCESSIBLE}
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




  test "explore logged as inline view" do
    data = Factory :small_test_spreadsheet_datafile,:policy=>Factory(:public_policy)
    assert_difference("ActivityLog.count") do
      get :explore,:id=>data
    end
    assert_response :success
    al = ActivityLog.last
    assert_equal data,al.activity_loggable
    assert_equal User.current_user,al.culprit
    assert_equal "inline_view",al.action
    assert_equal "data_files",al.controller_name
  end


  test "explore latest version" do
    data = Factory :small_test_spreadsheet_datafile,:policy=>Factory(:public_policy)
    get :explore,:id=>data
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

  test "correctly displays links in spreadsheet explorer" do
    df = Factory(:data_file,
                 :policy=>Factory(:public_policy),
                 :content_blob=>Factory(:small_test_spreadsheet_content_blob,:data=>File.new("#{Rails.root}/test/fixtures/files/spreadsheet_with_a_link.xls","rb").read))
    assert df.can_download?
    get :explore, :id=>df
    assert_response :success
    assert_select "td",:text=>"A link to BBC",:count=>1
    assert_select "td a[href=?][target=_blank]","http://bbc.co.uk/news",:count=>1
  end

  test "correctly displays rows in spreadsheet explorer" do
    df = Factory(:data_file,
                 :policy=>Factory(:public_policy),
                 :content_blob=>Factory(:small_test_spreadsheet_content_blob,:data=>File.new("#{Rails.root}/test/fixtures/files/spreadsheet_with_a_link.xls","rb").read))

    get :explore, :id=>df
    assert_response :success

    min_rows = Seek::Data::SpreadsheetExplorerRepresentation::MIN_ROWS
    assert_select "div#spreadsheet_1" do
      assert_select "div.row_heading", :count => min_rows
      (1..min_rows).each do |i|
        assert_select "div.row_heading", :text => "#{i}", :count => 1
      end

      assert_select "tr", :count => min_rows
      assert_select "td#cell_B2", :text => "A link to BBC", :count=>1
    end

    assert_select "div#spreadsheet_2" do
      assert_select "div.row_heading", :count => min_rows
      (1..min_rows).each do |i|
        assert_select "div.row_heading", :text => "#{i}", :count => 1
      end

      assert_select "tr", :count => min_rows
    end
  end

  test "correctly displays number of rows in spreadsheet explorer" do
    df = Factory(:data_file,
                 :policy=>Factory(:public_policy),
                 :content_blob=>Factory(:small_test_spreadsheet_content_blob,
                                        :data=>File.new("#{Rails.root}/test/fixtures/files/spreadsheet_with_a_link.xls","rb").read))

    get :explore, :id=>df, :page_rows => 5
    assert_response :success
    assert_select "div#spreadsheet_1" do
      assert_select "div.row_heading", :count => 5
      assert_select "tr", :count => 5
    end
  end

  test "correctly displays pagination in spreadsheet explorer" do
    df = Factory(:data_file,
                 :policy=>Factory(:public_policy),
                 :content_blob=>Factory(:small_test_spreadsheet_content_blob,
                                        :data=>File.new("#{Rails.root}/test/fixtures/files/spreadsheet_with_a_link.xls","rb").read))

    page_rows = Seek::Data::SpreadsheetExplorerRepresentation::MIN_ROWS/2 + 1
    get :explore, :id=>df, :page_rows => page_rows
    assert_response :success

    assert_select "div#paginate_sheet_1" do
      assert_select "span.previous_page.disabled", :text => /Previous/, :count => 1
      assert_select "em.current", :text => "1", :count => 1
      assert_select "a[href=?]", "/data_files/#{df.id}/explore?page=2&amp;page_rows=#{page_rows}&amp;sheet=1", :text => "2", :count => 1
      assert_select "a.next_page[href=?]", "/data_files/#{df.id}/explore?page=2&amp;page_rows=#{page_rows}&amp;sheet=1", :text => /Next/, :count => 1
    end

    assert_select "div#paginate_sheet_2" do
      assert_select "span.previous_page.disabled", :text => /Previous/, :count => 1
      assert_select "em.current", :text => "1", :count => 1
      assert_select "a[href=?]", "/data_files/#{df.id}/explore?page=2&amp;page_rows=#{page_rows}&amp;sheet=2", :text => "2", :count => 1
      assert_select "a.next_page[href=?]", "/data_files/#{df.id}/explore?page=2&amp;page_rows=#{page_rows}&amp;sheet=2", :text => /Next/, :count => 1
    end

    assert_select "div#paginate_sheet_3" do
      assert_select "span.previous_page.disabled", :text => /Previous/, :count => 1
      assert_select "em.current", :text => "1", :count => 1
      assert_select "a[href=?]", "/data_files/#{df.id}/explore?page=2&amp;page_rows=#{page_rows}&amp;sheet=3", :text => "2", :count => 1
      assert_select "a.next_page[href=?]", "/data_files/#{df.id}/explore?page=2&amp;page_rows=#{page_rows}&amp;sheet=3", :text => /Next/, :count => 1
    end
  end

  test "uploader can publish the item when projects associated with the item have no gatekeeper" do
    uploader = Factory(:user)
    data_file = Factory(:data_file, :contributor => uploader)
    assert_not_equal Policy::EVERYONE, data_file.policy.sharing_scope
    login_as(uploader)
    put :update, :id => data_file, :sharing => {:sharing_scope =>Policy::EVERYONE, "access_type_#{Policy::EVERYONE}".to_sym => Policy::VISIBLE}

    assert_nil flash[:error]
  end

  test "the person who has the manage right to the item, CAN publish the item, if no gatekeeper for projects associated with the item" do
    person = Factory(:person)
    policy = Factory(:policy)
    Factory(:permission, :policy => policy, :contributor => person, :access_type => Policy::MANAGING)
    data_file = Factory(:data_file, :policy => policy)
    assert data_file.gatekeepers.empty?
    assert_not_equal Policy::EVERYONE, data_file.policy.sharing_scope
    login_as(person.user)
    assert data_file.can_manage?
    put :update, :id => data_file, :sharing => {:sharing_scope =>Policy::EVERYONE, "access_type_#{Policy::EVERYONE}".to_sym => Policy::VISIBLE}

    assert_nil flash[:error]
  end

  test "the person who has the manage right to the item, CAN publish the item, if the item WAS published" do
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

  test "should enable the policy scope 'all visitor...' for the manager in case the asset needs gatekeeper's approval" do
    person = Factory(:person)
    policy = Factory(:policy)
    Factory(:permission, :policy => policy, :contributor => person, :access_type => Policy::MANAGING)

    project = Factory(:project)
    work_group = Factory(:work_group, :project => project)
    gatekeeper = Factory(:gatekeeper, :group_memberships => [Factory(:group_membership, :work_group => work_group)])

    data_file = Factory(:data_file, :policy => policy, :project_ids => [project.id])
    assert_not_equal Policy::EVERYONE, data_file.policy.sharing_scope
    login_as(person.user)
    assert data_file.can_manage?
    assert data_file.can_publish?
    assert data_file.gatekeeper_required?

    get :edit, :id => data_file

      assert_select "input[type=radio][id='sharing_scope_4'][value='4'][disabled='true']", :count => 0
  end

  test "should enable the policy scope 'all visitor...' for the manager in case the asset does not need gatekeeper's approval" do
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

  test "should not show private data file to logged out user" do
    df=Factory :data_file
    logout
    get :show, :id=>df
    assert_response :forbidden
  end

  test "should not show private data file to another user" do

    df=Factory :data_file,:contributor=>Factory(:user)
    get :show, :id=>df
    assert_response :forbidden
  end

  test "should show error for the user who doesn't login or is not the project member, when the user specify the version and this version is not the latest version" do
    published_data_file = Factory(:data_file, :policy => Factory(:public_policy))

    published_data_file.save_as_new_version
    Factory(:content_blob, :asset => published_data_file, :asset_version => published_data_file.version)
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

  test 'should show the other creators in  uploader and creators  box' do
    data_file=data_files(:picture)
    data_file.other_creators = 'another creator'
    data_file.save
    get :show, :id => data_file

    assert_select 'div', :text => /another creator/, :count => 1
  end

  test 'should select the correct sharing access_type when updating the datafile' do
    df = Factory(:data_file, :policy => Factory(:policy, :sharing_scope => Policy::EVERYONE, :access_type => Policy::ACCESSIBLE))
    login_as(df.contributor)

    get :edit, :id => df.id
    assert_response :success

    assert_select 'select#access_type_select_4' do
      assert_select "option[selected='selected']", :text => /#{I18n.t("access.accessible_downloadable")}/
    end
  end

  test "you should not subscribe to the asset created by the person whose projects overlap with you" do
    proj = Factory(:project)
    current_person = User.current_user.person
    current_person.project_subscriptions.create :project => proj, :frequency => 'weekly'
    a_person = Factory(:person)
    a_person.project_subscriptions.create :project => a_person.projects.first, :frequency => 'weekly'
    current_person.group_memberships << Factory(:group_membership,:work_group=>Factory(:work_group,:project=>a_person.projects.first))
    assert current_person.save
    assert current_person.reload.projects.include?(a_person.projects.first)
    assert Subscription.all.empty?

    df_param = { :title=>"Test",:project_ids=>[proj.id]}
    blob = {:data=>file_for_upload}
    post :create, :data_file => df_param,:content_blob=>blob, :sharing=>valid_sharing

    df = assigns(:data_file)

    assert SetSubscriptionsForItemJob.exists?(df.class.name, df.id, df.projects.collect(&:id))
    SetSubscriptionsForItemJob.new(df.class.name, df.id, df.projects.collect(&:id)).perform

    assert df.subscribed?(current_person)
    assert !df.subscribed?(a_person)
    assert_equal 1, current_person.subscriptions.count
    assert_equal proj, current_person.subscriptions.first.project_subscription.project
  end
    test "can move to presentations" do
     data_file = Factory :data_file, :contributor => User.current_user
     assert_difference("DataFile.count",  -1) do
       assert_difference("Presentation.count") do
         post :convert_to_presentation, :id => data_file
       end
     end
     assert assigns(:presentation)
     assert_redirected_to assigns(:presentation)
   end
 
   test "converting to presentation logs creation activity" do
     data_file = Factory :data_file,:contributor=>User.current_user
     assert_difference("ActivityLog.count") do
           post :convert_to_presentation, :id=>data_file
     end
     assert assigns(:presentation)
     presentation = assigns(:presentation)
 
     #needs to mimic the logging of a presentation being created
     al = ActivityLog.last
     assert_equal "create",al.action
     assert_equal User.current_user,al.culprit
     assert_equal presentation,al.activity_loggable
     assert_equal "data_files",al.controller_name
   end
 
   test "converted presentations have correct attributions" do
     data_file = Factory :data_file,:contributor=>User.current_user
     disable_authorization_checks {data_file.relationships.create :other_object => Factory(:data_file), :subject => data_file, :predicate => Relationship::ATTRIBUTED_TO}
     df_attributions = data_file.attributions_objects
     assert_difference("DataFile.count",  -1) do
       assert_difference("Presentation.count") do
         post :convert_to_presentation, :id=>data_file.id
       end
     end
 
     assert_equal df_attributions, assigns(:presentation).attributions_objects
     assert !assigns(:presentation).attributions_objects.empty?
   end


  test "project data files through nested routing" do
    assert_routing 'projects/2/data_files',{controller:"data_files",action:"index",project_id:"2"}
    df = Factory(:data_file,:policy=>Factory(:public_policy))
    project = df.projects.first
    df2 = Factory(:data_file,:policy=>Factory(:public_policy))
    get :index,:project_id=>project.id
    assert_response :success
    assert_select "div.list_item_title" do
      assert_select "p > a[href=?]",data_file_path(df),:text=>df.title
      assert_select "p > a[href=?]",data_file_path(df2),:text=>df2.title,:count=>0
    end
  end

  test "filtered data files for non existent study" do
    Factory :data_file #needs a data file to be sure that the problem being fixed is triggered
    study_id=999
    assert_nil Study.find_by_id(study_id)
    get :index,:study_id=>study_id
    assert_response :not_found
  end

  test "filtered data files for non existent project" do
    Factory :data_file #needs a data file to be sure that the problem being fixed is triggered
    project_id=999
    assert_nil Project.find_by_id(project_id)
    get :index,:project_id=>project_id
    assert_response :not_found
  end

  test "handles nil description" do
    df = Factory(:data_file,:description=>nil,:policy=>Factory(:public_policy))

    get :show,:id=>df
    assert_response :success
  end

  test "description formatting" do
    desc = "This is <b>Bold</b> - this is <em>emphasised</em> - this is super<sup>script</sup> - "
    desc << "This is <u>underlined</u> - "
    desc << "this is link to goole: http://google.com - "
    desc << "this is some nasty javascript <script>alert('fred');</script>"

    df = Factory(:data_file,:description=>desc,:policy=>Factory(:public_policy))

    get :show,:id=>df
    assert_response :success
    assert_select "div#description" do
      assert_select "p"
      assert_select "b", :text=>"Bold"
      assert_select "em", :text=>"emphasised"
      assert_select "u", :text=>"underlined"
      assert_select "sup", :text=>"script"
      assert_select "script",:count=>0
      assert_select "a[href=?]","http://google.com",:text=>"http://google.com"
    end

  end

  test "filter by people, including creators, using nested routes" do
    assert_routing "people/7/presentations",{controller:"presentations",action:"index",person_id:"7"}

    person1=Factory(:person)
    person2=Factory(:person)

    df1=Factory(:data_file,:contributor=>person1,:policy=>Factory(:public_policy))
    df2=Factory(:data_file,:contributor=>person2,:policy=>Factory(:public_policy))

    df3=Factory(:data_file,:contributor=>Factory(:person),:creators=>[person1],:policy=>Factory(:public_policy))
    df4=Factory(:data_file,:contributor=>Factory(:person),:creators=>[person2],:policy=>Factory(:public_policy))


    get :index,:person_id=>person1.id
    assert_response :success

    assert_select "div.list_item_title" do
      assert_select "a[href=?]",data_file_path(df1),:text=>df1.title
      assert_select "a[href=?]",data_file_path(df3),:text=>df3.title

      assert_select "a[href=?]",data_file_path(df2),:text=>df2.title,:count=>0
      assert_select "a[href=?]",data_file_path(df4),:text=>df4.title,:count=>0
    end

  end

  test "edit should include tags element" do
    df = Factory(:data_file,:policy=>Factory(:public_policy))
    get :edit, :id=>df.id
    assert_response :success

    assert_select "div.foldTitle",:text=>/Tags/,:count=>1
    assert_select "div#tag_ids",:count=>1
  end

  test "new should include tags element" do
    get :new
    assert_response :success
    assert_select "div.foldTitle",:text=>/Tags/,:count=>1
    assert_select "div#tag_ids",:count=>1
  end

  test "new with biovel sharing form" do
    with_alternative_rendering({:seek_partial=>"assets/sharing_form"},"assets/sharing_form_biovel") do
      get :new
      assert_response :success
    end
  end

  test "edit with biovel sharing form" do
    with_alternative_rendering({:seek_partial=>"assets/sharing_form"},"assets/sharing_form_biovel") do
      df = Factory :data_file,:policy=>Factory(:public_policy)
      get :edit, :id=>df
      assert_response :success
    end
  end

  test "edit should include not include tags element when tags disabled" do
    with_config_value :tagging_enabled,false do
      df = Factory(:data_file,:policy=>Factory(:public_policy))
      get :edit, :id=>df.id
      assert_response :success

      assert_select "div.foldTitle",:text=>/Tags/,:count=>0
      assert_select "div#tag_ids",:count=>0
    end
  end

  test "new should not include tags element when tags disabled" do
    with_config_value :tagging_enabled,false do
      get :new,:class=>:experimental
      assert_response :success
      assert_select "div.foldTitle",:text=>/Tags/,:count=>0
      assert_select "div#tag_ids",:count=>0
    end
  end

  test "get data_file as json" do
    df = Factory(:data_file,:policy=>Factory(:public_policy),:title=>"fish flop",:description=>"testing json description")
    get :show,:id=>df,:format=>"json"
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal df.id,json["id"]
    assert_equal "fish flop",json["title"]
    assert_equal "testing json description",json["description"]
    assert_equal df.version,json["version"]
  end

  test "landing page for hidden item" do
    df = Factory(:data_file,:policy=>Factory(:private_policy),:title=>"fish flop",:description=>"testing json description")
    assert !df.can_view?

    get :show,:id=>df
    assert_response :forbidden
    assert_select "h2",:text=>/The #{I18n.t('data_file')} is not visible to you./

    assert !df.can_see_hidden_item?(User.current_user.person)
    contributor_person = df.contributor.person
    assert_select "a[href=?]", person_path(contributor_person), :count => 0
  end

  test "landing page for hidden item with the contributor contact" do
    df = Factory(:data_file,:policy=>Factory(:private_policy),:title=>"fish flop",:description=>"testing json description")

    project = df.projects.first
    work_group = Factory(:work_group, project: project)
    person = Factory(:person_in_project, group_memberships: [Factory(:group_membership, work_group: work_group)])
    user = Factory(:user, person: person)

    login_as(user)

    assert !df.can_view?
    assert df.can_see_hidden_item?(user.person)

    get :show,:id=>df
    assert_response :forbidden
    assert_select "h2",:text=>/The #{I18n.t('data_file')} is not visible to you./

    contributor_person = df.contributor.person
    assert_select "a[href=?]", person_path(contributor_person)
  end

  test "landing page for hidden item which DOI was minted" do
    df = Factory(:data_file,:policy=>Factory(:private_policy),:title=>"fish flop",:description=>"testing json description")
    comment = 'the paper was retracted'
    AssetDoiLog.create(:asset_type => df.class.name, :asset_id=> df.id, :asset_version => df.version, :action => AssetDoiLog::MINT)
    AssetDoiLog.create(:asset_type => df.class.name, :asset_id=> df.id, :asset_version => df.version, :action => AssetDoiLog::UNPUBLISH, :comment => comment)

    assert !df.can_view?
    assert AssetDoiLog.was_doi_minted_for?(df.class.name, df.id, df.version)

    get :show,:id=>df
    assert_response :forbidden
    assert_select "p[class=comment]",:text=>/#{comment}/
  end

  test "landing page for non-existing item" do
    get :show,:id=>123
    assert_response :not_found
    assert_select "h1", :text=>'404'
    assert_select "h2",:text=>/The #{I18n.t('data_file')} does not exist./
  end

  test "landing page for deleted item which DOI was minted" do
    comment = 'the paper was restracted'
    klass = 'DataFile'
    id = 123
    version = 1
    AssetDoiLog.create(:asset_type => klass, :asset_id=> id, :asset_version => version, :action => AssetDoiLog::MINT)
    AssetDoiLog.create(:asset_type => klass, :asset_id=> id, :asset_version => version, :action => AssetDoiLog::DELETE, :comment => comment)
    assert AssetDoiLog.was_doi_minted_for?(klass, id, version)
    get :show,:id=>id, :version=>version
    assert_response :not_found
    assert_select "p[class=comment]",:text=>/#{comment}/
  end

  private

  def mock_http
    stub_request(:get, "http://mockedlocation.com/a-piccy.png").to_return(:body => File.new("#{Rails.root}/test/fixtures/files/file_picture.png"), :status => 200, :headers=>{'Content-Type' => 'image/png'})
    stub_request(:head, "http://mockedlocation.com/a-piccy.png").to_return(:status => 200, :headers=>{'Content-Type' => 'image/png'})

    stub_request(:get, "http://mockedlocation.com/txt_test.txt").to_return(:body => File.new("#{Rails.root}/test/fixtures/files/txt_test.txt"), :status => 200, :headers=>{'Content-Type' => 'text/plain; charset=UTF-8'})
    stub_request(:head, "http://mockedlocation.com/txt_test.txt").to_return(:status=>200,headers: { content_type: 'text/plain; charset=UTF-8' })

    stub_request(:head, "http://redirectlocation.com").to_return(:status=>200,headers: {content_type: 'text/html'})
    stub_request(:get, "http://redirectlocation.com").to_return(:body=>"<html><head></head><body></body></html>",:status=>200,headers: {content_type: 'text/html'})

    stub_request(:any, "http://mocked301.com").to_return(:status=>301, :headers=>{:location=>"http://redirectlocation.com"})
    stub_request(:any, "http://mocked302.com").to_return(:status=>302, :headers=>{:location=>"http://redirectlocation.com"})
    stub_request(:any, "http://mocked401.com").to_return(:status=>401)
    stub_request(:any, "http://mocked403.com").to_return(:status=>403)
    stub_request(:any, "http://mocked404.com").to_return(:status=>404)
  end

  def mock_https
    file="#{Rails.root}/test/fixtures/files/txt_test.txt"
    stub_request(:get, "https://mockedlocation.com/txt_test.txt").to_return(:body => File.new(file), :status => 200, :headers=>{'Content-Type' => 'text/plain; charset=UTF-8'})
    stub_request(:head, "https://mockedlocation.com/txt_test.txt").to_return(:status=>200,headers: { content_type: 'text/plain; charset=UTF-8' })

    stub_request(:head, "https://redirectlocation.com").to_return(:status=>200,headers: {content_type: 'text/html'})

    stub_request(:any, "https://mocked301.com").to_return(:status=>301, :headers=>{:location=>"https://redirectlocation.com"})
    stub_request(:any, "https://mocked302.com").to_return(:status=>302, :headers=>{:location=>"https://redirectlocation.com"})
    stub_request(:any, "https://mocked401.com").to_return(:status=>401)
    stub_request(:any, "https://mocked404.com").to_return(:status=>404)
  end

  def file_for_upload
    ActionDispatch::Http::UploadedFile.new({
                                               :filename => 'file_picture.png',
                                               :content_type => 'image/png',
                                               :tempfile => fixture_file_upload('files/file_picture.png')
                                           })
  end
  def valid_data_file
    return { :title=>"Test",:project_ids=>[projects(:sysmo_project).id]},{:data=>file_for_upload}
  end
  
  def valid_data_file_with_http_url
    return { :title=>"Test HTTP",:project_ids=>[projects(:sysmo_project).id]},{:data_url=>"http://mockedlocation.com/txt_test.txt",:make_local_copy=>"0"}
  end

  def valid_data_file_with_https_url
    return { :title=>"Test HTTP",:project_ids=>[projects(:sysmo_project).id]},{:data_url=>"https://mockedlocation.com/txt_test.txt",:make_local_copy=>"0"}
  end
end
