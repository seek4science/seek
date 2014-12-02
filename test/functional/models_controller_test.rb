require 'test_helper'

class ModelsControllerTest < ActionController::TestCase
  
  fixtures :all
  
  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper
  include RdfTestCases
  include FunctionalAuthorizationTests

  #MERGENOTE - needs tests for adding multiple files, urls, and a mixture
  
  def setup
    login_as(:model_owner)
  end

  def rest_api_test_object
    @object=Factory :model_2_files, :contributor=>User.current_user, :policy=>Factory(:private_policy),:organism=>Factory(:organism)

  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:models)
  end

  test "should not download private" do
    model = Factory :model_2_files, :policy=>Factory(:private_policy)
    assert !model.can_download?(User.current_user)
    assert_no_difference("ActivityLog.count") do
      get :download,:id=>model.id
    end
    assert_redirected_to model_path(model)
    assert_not_nil flash[:error]
  end

  test "should download without type information" do
    model = Factory :typeless_model, :policy=>Factory(:public_policy)
    assert model.can_download?
    assert_difference("ActivityLog.count") do
      get :download, :id=>model.id
    end
    assert_response :success
    assert_equal "attachment; filename=\"file_with_no_extension\"",@response.header['Content-Disposition']
    assert_equal "application/octet-stream",@response.header['Content-Type']
    assert_equal "31",@response.header['Content-Length']
  end

  test "should download" do
    model = Factory :model_2_files, :title=>"this_model", :policy=>Factory(:public_policy), :contributor=>User.current_user
    assert_difference("ActivityLog.count") do
      get :download, :id=>model.id
    end
    assert_response :success
    assert_equal "attachment; filename=\"this_model.zip\"",@response.header['Content-Disposition']
    assert_equal "application/zip",@response.header['Content-Type']
    assert_equal "3024",@response.header['Content-Length']
  end

  test "should download model with a single file" do
    model = Factory :model, :title=>"this_model", :policy=>Factory(:public_policy), :contributor=>User.current_user
    assert_difference("ActivityLog.count") do
      get :download, :id=>model.id
    end
    assert_response :success
    assert_equal "attachment; filename=\"cronwright.xml\"",@response.header['Content-Disposition']
    assert_equal "text/xml",@response.header['Content-Type']
    assert_equal "5933",@response.header['Content-Length']
  end

  test "should download multiple files with the same name" do
    #2 files with different names
    model = Factory :model_2_files, :policy=>Factory(:public_policy), :contributor=>User.current_user
    get :download, :id=>model.id
    assert_response :success
    assert_equal "application/zip", @response.header['Content-Type']
    assert_equal "3024", @response.header['Content-Length']
    zip_file_size1 = @response.header['Content-Length'].to_i

    #3 files, 2 of them have the same name
    first_content_blob = model.content_blobs.first
    third_content_blob = Factory(:cronwright_model_content_blob, :asset => model,:asset_version=>model.version)
    assert_equal first_content_blob.original_filename, third_content_blob.original_filename
    model.content_blobs << third_content_blob

    get :download, :id=>model.id
    assert_response :success
    assert_equal "application/zip", @response.header['Content-Type']
    assert_equal "4023", @response.header['Content-Length']
    zip_file_size2 = @response.header['Content-Length'].to_i

    #the same name file is not overwriten, by checking the zip file size
    assert_not_equal zip_file_size1, zip_file_size2
  end

  test "should not create model with file url" do
    file_path=File.expand_path(__FILE__) #use the current file
    file_url="file://"+file_path
    uri=URI.parse(file_url)    
   
    assert_no_difference('Model.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :model => { :title=>"Test"},:content_blob=>{:data_url_0=>uri.to_s}, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash[:error]    
  end


  test 'creators show in list item' do
    p1=Factory :person
    p2=Factory :person
    model=Factory(:model,:title=>"ZZZZZ",:creators=>[p2],:contributor=>p1.user,:policy=>Factory(:public_policy, :access_type=>Policy::VISIBLE))

    get :index,:page=>"Z"

    #check the test is behaving as expected:
    assert_equal p1.user,model.contributor
    assert model.creators.include?(p2)
    assert_select ".list_item_title a[href=?]",model_path(model),"ZZZZZ","the data file for this test should appear as a list item"

    #check for avatars: uploader won't be shown if he/she is not creator
    assert_select ".list_item_avatar" do
      assert_select "a[href=?]",person_path(p2) do
        assert_select "img"
      end

    end
  end

  
  test "shouldn't show hidden items in index" do
    login_as(:aaron)
    get :index, :page => "all"
    assert_response :success
    assert_equal assigns(:models).sort_by(&:id), Model.authorize_asset_collection(assigns(:models), "view", users(:aaron)).sort_by(&:id), "models haven't been authorized properly"
  end

  test "should contain only model assays " do
    login_as(:aaron)
    assay = assays(:metabolomics_assay)
    assert_equal false, assay.is_modelling?
    assay = assays(:modelling_assay_with_data_and_relationship)
    assert_equal true, assay.is_modelling?

  end

  test "should show only modelling assays in associate modelling analysis form" do
    login_as(:model_owner)
    as_not_virtualliver do
      get :new
      assert_response :success
      assert_select 'select#possible_assays' do
        assert_select "option", :text=>/Select #{I18n.t('assays.assay')} .../,:count=>1
        assert_select "option", :text=>/Modelling Assay/,:count=>1
        assert_select "option", :text=>/Metabolomics Assay/,:count=>0
      end
    end

    as_virtualliver do
    #show all can_view assays in the list
      get :new
      assert_response :success
      assert_select 'select#possible_assays' do
        assert_select "option", :text=>/Select #{I18n.t('assays.assay')} .../,:count=>1
        assert_select "option", :text=>/Modelling Assay/,:count=>5
        assert_select "option", :text=>/Metabolomics Assay/,:count=>0
      end
    end
  end

  test "correct title and text for associating a modelling analysis for new" do
    login_as(Factory(:user))
    as_virtualliver do
      get :new
      assert_response :success
      assert_select 'div.association_step p', :text => /You may select an existing editable #{I18n.t('assays.modelling_analysis')} or create new #{I18n.t('assays.modelling_analysis')} to associate with this #{I18n.t('model')}./
    end
    as_not_virtualliver do
      get :new
      assert_response :success
      assert_select 'div.association_step p', :text => /You may select an existing editable #{I18n.t('assays.modelling_analysis')} to associate with this #{I18n.t('model')}./
    end
    assert_select 'div.foldTitle', :text => /#{I18n.t('assays.modelling_analysis').pluralize}/
    assert_select 'div#associate_assay_fold_content p', :text => /The following #{I18n.t('assays.modelling_analysis').pluralize} are associated with this #{I18n.t('model')}:/
  end

  test "correct title and text for associating a modelling analysis for edit" do
    model = Factory :model
    login_as(model.contributor.user)
    as_virtualliver do

      get :edit, :id=>model.id
      assert_response :success
      assert_select 'div.association_step p',:text=>/You may select an existing editable #{I18n.t('assays.modelling_analysis')} or create new #{I18n.t('assays.modelling_analysis')} to associate with this #{I18n.t('model')}./
    end
    as_not_virtualliver do
      get :edit, :id=>model.id
      assert_response :success
      assert_select 'div.association_step p',:text=>/You may select an existing editable #{I18n.t('assays.modelling_analysis')} to associate with this #{I18n.t('model')}./
    end
    assert_select 'div.foldTitle',:text=>/#{I18n.t('assays.modelling_analysis').pluralize}/
    assert_select 'div#associate_assay_fold_content p',:text=>/The following #{I18n.t('assays.modelling_analysis').pluralize} are associated with this #{I18n.t('model')}:/
  end

  test "fail gracefullly when trying to access a missing model" do
    get :show,:id=>99999
    assert_response :not_found
  end
  
  test "should get new as non admin" do
    get :new    
    assert_response :success
    assert_select "h1",:text=>"New #{I18n.t('model')}"

    #non admins can't edit types
    assert_select "span#delete_model_type_icon",:count=>0
  end

  test "should get new as admin" do
    login_as(Factory(:admin).user)
    get :new
    assert_response :success
  end
  
  test "should correctly handle bad data url" do
    stub_request(:any,"http://sdfsdfkh.com/sdfsd.png").to_raise(SocketError)
    model={:title=>"Test",:project_ids=>[projects(:sysmo_project).id]}
    blob={:data_url_0=>"http://sdfsdfkh.com/sdfsd.png",:original_filename_0=>"",:make_local_copy_0=>"0"}
    assert_no_difference('Model.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :model => model,:content_blob=>blob, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash.now[:error]
  end
  
  test "should not create invalid model" do
    model={:title=>"Test"}
    assert_no_difference('Model.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :model => model,:content_blob=>{}, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash.now[:error]
  end

  test "associates assay" do
    login_as(:model_owner) #can edit assay_can_edit_by_my_first_sop_owner
    m = models(:teusink)
    original_assay = assays(:assay_with_a_model)
    asset_ids = original_assay.related_asset_ids 'Model'
    assert asset_ids.include? m.id
    new_assay=assays(:modelling_assay)
    new_asset_ids = new_assay.related_asset_ids 'Model'
    assert !new_asset_ids.include?(m.id)

    put :update, :id => m, :model =>{}, :assay_ids=>[new_assay.id.to_s]

    assert_redirected_to model_path(m)
    m.reload
    original_assay.reload
    new_assay.reload
    assert !original_assay.related_asset_ids('Model').include?(m.id)
    assert new_assay.related_asset_ids('Model').include?(m.id)
    end

  test "associate sample" do
     # assign to a new model
     model_with_samples = valid_model
     model_with_samples[:sample_ids] = [Factory(:sample,:title=>"newTestSample",:contributor=> User.current_user).id]
     assert_difference("Model.count") do
       post :create,:model => model_with_samples,:content_blob=>{:data_0=>file_for_upload}, :sharing => valid_sharing
     end

    m = assigns(:model)
    assert_equal "newTestSample", m.samples.first.title

    #edit associations of samples to an existing model
    put :update,:id=> m.id, :model => {:sample_ids=> [Factory(:sample,:title=>"editTestSample",:contributor=> User.current_user).id]}
    m = assigns(:model)
    assert_equal "editTestSample", m.samples.first.title
  end

  test "association of scales" do
    scale1=Factory :scale, :pos=>1
    scale2=Factory :scale, :pos=>2
    model_params = valid_model

    assert_difference("Model.count") do
      post :create,:model => model_params,:scale_ids=>[scale1.id.to_s,scale2.id.to_s],:content_blob=>{:data_0=>file_for_upload}, :sharing => valid_sharing
    end
    m = assigns(:model)
    assert_not_nil m
    assert_equal [scale1,scale2],m.scales
    scale3 = Factory(:scale)

    put :update,:id=> m.id, :scale_ids=>[scale3.id.to_s]
    m = assigns(:model)
    assert_equal [scale3],m.scales
  end

  test "association of scales with params" do
    scale1=Factory :scale, :pos=>1
    scale2=Factory :scale, :pos=>2
    model_params = valid_model
    scale_ids_and_params=["{\"scale_id\":\"#{scale1.id}\",\"param\":\"fish\",\"unit\":\"meter\"}",
                          "{\"scale_id\":\"#{scale2.id}\",\"param\":\"carrot\",\"unit\":\"cm\"}",
                          "{\"scale_id\":\"#{scale1.id}\",\"param\":\"soup\",\"unit\":\"minute\"}"]

    assert_difference("Model.count") do
      post :create,:model => model_params,:scale_ids=>[scale1.id.to_s,scale2.id.to_s],:scale_ids_and_params=>scale_ids_and_params,:content_blob=>{:data_0=>file_for_upload}, :sharing => valid_sharing
    end
    m = assigns(:model)
    assert_not_nil m
    assert_equal [scale1,scale2],m.scales

    info = m.fetch_additional_scale_info(scale1.id)
    assert_equal 2,info.count
    info.sort!{|a,b| a["param"]<=>b["param"]}

    assert_equal "fish",info[0]["param"]
    assert_equal "meter",info[0]["unit"]
    assert_equal "soup",info[1]["param"]
    assert_equal "minute",info[1]["unit"]

    info = m.fetch_additional_scale_info(scale2.id)
    assert_equal 1,info.count
    info = info.first
    assert_equal "carrot",info["param"]
    assert_equal "cm",info["unit"]
  end

  test "should create model" do
    login_as(:model_owner)
    assay = assays(:modelling_assay)
    assert_difference('Model.count') do
      post :create, :model => valid_model,:content_blob=>{:data_0=>file_for_upload}, :sharing=>valid_sharing, :assay_ids => [assay.id.to_s]
    end
    
    assert_redirected_to model_path(assigns(:model))
    assay.reload
    assert assay.related_asset_ids('Model').include? assigns(:model).id
  end

  def test_missing_sharing_should_default_to_blank_for_vln
    with_config_value "is_virtualliver",true do
      assert_no_difference('Model.count') do
        assert_no_difference('ContentBlob.count') do
          post :create, :model => valid_model,:content_blob=>{:data_0=>file_for_upload}
        end
      end

      m = assigns(:model)
      assert !m.valid?
      assert !m.policy.valid?
      assert_blank m.policy.sharing_scope
      assert_blank m.policy.access_type
      assert_blank m.policy.permissions
    end
  end

  def test_missing_sharing_should_default_to_private
    with_config_value "is_virtualliver",false do
      assert_difference('Model.count',1) do
        assert_difference('ContentBlob.count',1) do
          post :create, :model => valid_model,:content_blob=>{:data_0=>file_for_upload}
        end
      end

      m = assigns(:model)
      assert m.valid?
      assert m.policy.valid?
      assert_equal Policy::PRIVATE, m.policy.sharing_scope
      assert_equal Policy::NO_ACCESS, m.policy.access_type
      assert_blank m.policy.permissions
    end
  end
  

  test "should create model with image" do
      login_as(:model_owner)
      assert_difference('Model.count') do
        assert_difference('ModelImage.count') do
          post :create, :model => valid_model,:content_blob=>{:data_0=>file_for_upload}, :sharing=>valid_sharing, :model_image => {:image_file => fixture_file_upload('files/file_picture.png', 'image/png')}
        end
      end

      model = assigns(:model)
      assert_redirected_to model_path(model)
      assert_equal "file_picture.png", model.model_image.original_filename
      assert_equal "image/png", model.model_image.content_type
  end

  test "should create model with image and without content_blob" do
      login_as(:model_owner)
      assert_difference('Model.count') do
        assert_difference('ModelImage.count') do
          post :create, :model => valid_model,:content_blob=>{}, :sharing=>valid_sharing, :model_image => {:image_file => fixture_file_upload('files/file_picture.png', 'image/png')}
        end
      end

      model = assigns(:model)
      assert_redirected_to model_path(model)
      assert_equal 'Test', model.title
  end

  test "should not create model without image and without content_blob" do
      login_as(:model_owner)
      assert_no_difference('Model.count') do
          post :create, :model => valid_model,:content_blob=>{}, :sharing=>valid_sharing
      end
      assert_not_nil flash[:error]
  end

  test "should create model version with image" do
    m=models(:model_with_format_and_type)
    assert_difference("Model::Version.count", 1) do
      assert_difference('ModelImage.count') do
        post :new_version, :id => m, :content_blob => {:data_0 => file_for_upload(:filename => "little_file.txt")}, :revision_comment => "This is a new revision", :model_image => {:image_file => fixture_file_upload('files/file_picture.png', 'image/png')}
      end
    end

    assert_redirected_to model_path(m)
    assert assigns(:model)

    m=Model.find(m.id)
    assert_equal 2, m.versions.size
    assert_equal 2, m.version
    assert_equal 1, m.content_blobs.size
    assert_equal 1, m.versions[1].content_blobs.size
    assert_equal 1, m.model_images.count
    assert_equal 'image/png',m.model_images[0].content_type
    assert_equal m.content_blobs, m.versions[1].content_blobs
    assert File.exist?(m.model_images[0].file_path)
    assert_equal "little_file.txt", m.content_blobs.first.original_filename
    assert_equal "little_file.txt", m.versions[1].content_blobs.first.original_filename
    assert_equal "This is a new revision", m.versions[1].revision_comments
    assert_equal "Teusink.xml", m.versions[0].content_blobs.first.original_filename
  end

  test "should create model with import details" do
    user = Factory :user
    login_as(user)
    model_details = valid_model
    model_details[:imported_source]="BioModels"
    model_details[:imported_url]="http://biomodels/model.xml"

    assert_difference('Model.count') do
      post :create, :model => model_details, :sharing=>valid_sharing,:content_blob=>{:data_0=>file_for_upload}, :sharing=>valid_sharing, :model_image => {:image_file => fixture_file_upload('files/file_picture.png', 'image/png')}
    end
    model = assigns(:model)
    assert_redirected_to model_path(model)
    assert_equal "BioModels",model.imported_source
    assert_equal "http://biomodels/model.xml",model.imported_url
    assert_equal user, model.contributor
  end
  
  test "should create model with url" do
    model,blob = valid_model_with_url
    assert_difference('Model.count') do
      assert_difference('ContentBlob.count') do
        post :create, :model =>model ,:content_blob=>blob, :sharing=>valid_sharing
      end
    end
    model = assigns(:model)
    assert_redirected_to model_path(model)
    assert_equal users(:model_owner),model.contributor
    assert_equal 1,model.content_blobs.count
    assert !model.content_blobs.first.url.blank?
    assert model.content_blobs.first.data_io_object.nil?
    assert !model.content_blobs.first.file_exists?
    assert_equal "sysmo-db-logo-grad2.png", model.content_blobs.first.original_filename
    assert_equal "image/png", model.content_blobs.first.content_type
  end
  
  test "should create model and store with url and store flag" do
    model_details,blob=valid_model_with_url
    blob[:make_local_copy_0]="1"
    assert_difference('Model.count') do
      assert_difference('ContentBlob.count') do
        post :create, :model => model_details,:content_blob=>blob, :sharing=>valid_sharing
      end
    end
    model = assigns(:model)
    assert_redirected_to model_path(model)
    assert_equal users(:model_owner),model.contributor
    assert_equal 1,model.content_blobs.count
    assert !model.content_blobs.first.url.blank?


    assert !model.content_blobs.first.data_io_object.nil?
    assert model.content_blobs.first.file_exists?
    assert_equal "sysmo-db-logo-grad2.png", model.content_blobs.first.original_filename
    assert_equal "image/png", model.content_blobs.first.content_type
  end



  test "should add webpage with a 301 redirect" do
    #you need to stub out both the redirecting url and the forwarded location url
    stub_request(:head, "http://news.bbc.co.uk").to_return(:status=>301,:headers=>{'Location'=>'http://bbc.co.uk/news'})
    stub_request(:head, "http://bbc.co.uk/news").to_return(:status=>200,:headers=>{'Content-Type' => 'text/html'})
    model,blob = valid_model_with_url
    assert_difference('Model.count') do
      assert_difference('ContentBlob.count') do
        post :create, :model => model,:content_blob=>{:data_url_0=>"http://news.bbc.co.uk"}, :sharing=>valid_sharing
      end
    end
    model = assigns(:model)
    assert_redirected_to model_path(model)
    assert_equal users(:model_owner),model.contributor
    assert_equal 1,model.content_blobs.count
    assert_equal "http://news.bbc.co.uk",model.content_blobs.first.url
    assert model.content_blobs.first.is_webpage?



  end
  
  test "should create with preferred environment" do
    assert_difference('Model.count') do
      model=valid_model
      model[:recommended_environment_id]=recommended_model_environments(:jws).id
      post :create, :model => model,:content_blob=>{:data_0=>file_for_upload} ,:sharing=>valid_sharing
    end
    
    m=assigns(:model)
    assert m
    assert_equal "JWS Online",m.recommended_environment.title
  end
  
  test "should show model" do
    m = Factory :model,:policy=>Factory(:public_policy)
    assert_difference('ActivityLog.count') do
      get :show, :id => m
    end

    assert_response :success

    assert_select "div.box_about_actor" do
      assert_select "p > strong",:text=>"1 item is associated with this #{I18n.t('model')}:"
      assert_select "ul.fileinfo_list" do
        assert_select "li.fileinfo_container > div.fileinfo" do
            assert_select "p > b",:text=>"Filename:"
            assert_select "p > span.filename",:text=>"cronwright.xml"
            assert_select "p > b",:text=>"Format:"
            assert_select "p > span.format",:text=>"XML document"
            assert_select "p > b",:text=>"Size:"
            assert_select "p > span.filesize",:text=>"5.79 KB"
        end
      end
    end

    assert_select "p.import_details",:count=>0
  end

  test "should show model with multiple files" do
    m = Factory :model_2_files,:policy=>Factory(:public_policy)

    assert_difference('ActivityLog.count') do
      get :show, :id => m
    end

    assert_response :success

    assert_select "div.box_about_actor" do
      assert_select "p > strong",:text=>"2 items are associated with this #{I18n.t('model')}:"
      assert_select "ul.fileinfo_list" do
        assert_select "li.fileinfo_container",:count=>2 do
          assert_select "p > b",:text=>"Filename:",:count=>2
          assert_select "p > span.filename",:text=>/cronwright\.xml/
          assert_select "p > span.filename",:text=>/rightfield\.xls/
          assert_select "p > b",:text=>"Format:",:count=>2
          assert_select "p > span.format",:text=>"XML document"
          assert_select "p > span.format",:text=>"Spreadsheet"
          assert_select "p > b",:text=>"Size:",:count=>2
          assert_select "p > span.filesize",:text=>"5.79 KB"
          assert_select "p > span.filesize",:text=>"9 KB"
        end
      end
    end
  end

  test "should show model with import details" do
    m = Factory :model,:policy=>Factory(:public_policy), :imported_source=>"Some place",:imported_url=>"http://somewhere/model.xml"
    assert_difference('ActivityLog.count') do
      get :show, :id => m
    end

    assert_response :success
    assert_select "p.import_details",:text=>/This #{I18n.t('model')} was originally imported from/ do
      assert_select "strong",:text=>"Some place"
      assert_select "a[href=?][target='_blank']","http://somewhere/model.xml",:text=>"http://somewhere/model.xml"
    end

  end

  
  test "should show model with format and type" do
    m = models(:model_with_format_and_type)
    m.save
    get :show, :id => m
    assert_response :success
  end
  
  test "should get edit" do
    get :edit, :id => models(:teusink)
    assert_response :success
    assert_select "h1",:text=>/Editing #{I18n.t('model')}/
  end
  
  test "publications included in form for model" do
    
    get :edit, :id => models(:teusink)
    assert_response :success
    assert_select "div#publications_fold_content",true
    
    get :new
    assert_response :success
    assert_select "div#publications_fold_content",true
  end
  
  test "should update model" do
    put :update, :id => models(:teusink).id, :model => { }
    assert_redirected_to model_path(assigns(:model))
  end
  
  test "should update model with model type and format" do
    type=model_types(:ODE)
    format=model_formats(:SBML)
    put :update, :id => models(:teusink).id, :model => {:model_type_id=>type.id,:model_format_id=>format.id }
    assert assigns(:model)
    assert_equal type,assigns(:model).model_type
    assert_equal format,assigns(:model).model_format
  end
  
  test "should destroy model" do
    assert_difference('Model.count', -1) do
      assert_no_difference("ContentBlob.count") do
        delete :destroy, :id => models(:teusink).id
      end
    end
    
    assert_redirected_to models_path
  end
  
  def test_should_show_version

    m = models(:model_with_format_and_type)
    m.save! #to force creation of initial version (fixtures don't include it)

    #create new version
    assert_difference("Model::Version.count", 1) do
      post :new_version, :id=>m, :content_blob=>{:data_0=>file_for_upload(:filename=>"little_file.txt")}
    end
    assert_redirected_to model_path(assigns(:model))
    m = Model.find(m.id)
    assert_equal 2, m.versions.size
    assert_equal 2, m.version
    assert_equal 1, m.versions[0].version
    assert_equal 2, m.versions[1].version
    
    get :show, :id=>models(:model_with_format_and_type)
    assert_select "p", :text=>/little_file.txt/, :count=>1
    assert_select "p", :text=>/Teusink.xml/, :count=>0
    
    get :show, :id=>models(:model_with_format_and_type), :version=>"2"
    assert_select "p", :text=>/little_file.txt/, :count=>1
    assert_select "p", :text=>/Teusink.xml/, :count=>0
    
    get :show, :id=>models(:model_with_format_and_type), :version=>"1"
    assert_select "p", :text=>/little_file.txt/, :count=>0
    assert_select "p", :text=>/Teusink.xml/, :count=>1
    
  end
  
  def test_should_create_new_version
    m=models(:model_with_format_and_type)
    assert_difference("Model::Version.count", 1) do
      post :new_version, :id=>m, :model=>{},:content_blob=>{:data_0=>file_for_upload(:filename=>"little_file.txt")}, :revision_comment=>"This is a new revision"
    end
    
    assert_redirected_to model_path(m)
    assert assigns(:model)
    assert_not_nil flash[:notice]
    assert_nil flash[:error]
    
    m=Model.find(m.id)
    assert_equal 2,m.versions.size
    assert_equal 2,m.version
    assert_equal 1,m.content_blobs.size
    assert_equal m.content_blobs,m.versions[1].content_blobs
    assert_equal "little_file.txt",m.content_blobs.first.original_filename
    assert_equal "little_file.txt",m.versions[1].content_blobs.first.original_filename
    assert_equal "Teusink.xml",m.versions[0].content_blobs.first.original_filename
    assert_equal "This is a new revision",m.versions[1].revision_comments
    
  end

  def test_should_add_nofollow_to_links_in_show_page
    get :show, :id=> models(:model_with_links_in_description)    
    assert_select "div#description" do
      assert_select "a[rel=nofollow]"
    end
  end
  
  def test_update_should_not_overwrite_contributor
    login_as(:model_owner) #this user is a member of sysmo, and can edit this model
    model=models(:model_with_no_contributor)
    put :update, :id => model, :model => {:title=>"blah blah blah blah" }
    updated_model=assigns(:model)
    assert_redirected_to model_path(updated_model)
    assert_equal "blah blah blah blah",updated_model.title,"Title should have been updated"
    assert_nil updated_model.contributor,"contributor should still be nil"
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
    person = people(:person_for_model_owner)
    get :index,:filter=>{:person=>person.id},:page=>"all"
    assert_response :success    
    m = models(:model_with_format_and_type)
    m2 = models(:model_with_different_owner)
    assert_select "div.list_items_container" do      
      assert_select "a",:text=>m.title,:count=>1
      assert_select "a",:text=>m2.title,:count=>0
    end
  end

  test "should not be able to update sharing without manage rights" do
    login_as(:quentin)
    user = users(:quentin)
    model   = models(:model_with_links_in_description)

    assert model.can_edit?(user), "sop should be editable but not manageable for this test"
    assert !model.can_manage?(user), "sop should be editable but not manageable for this test"
    assert_equal Policy::EDITING, model.policy.access_type, "data file should have an initial policy with access type for editing"
    put :update, :id => model, :model => {:title=>"new title"}, :sharing=>{:use_whitelist=>"0", :user_blacklist=>"0", :sharing_scope =>Policy::ALL_SYSMO_USERS, "access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::NO_ACCESS}
    assert_redirected_to model_path(model)
    model.reload

    assert_equal "new title", model.title
    assert_equal Policy::EDITING, model.policy.access_type, "policy should not have been updated"
  end

  test "owner should be able to update sharing" do
    login_as(:model_owner)
    user = users(:model_owner)
    model   = models(:model_with_links_in_description)

    assert model.can_edit?(user), "sop should be editable and manageable for this test"
    assert model.can_manage?(user), "sop should be editable and manageable for this test"
    assert_equal Policy::EDITING, model.policy.access_type, "data file should have an initial policy with access type for editing"
    put :update, :id => model, :model => {:title=>"new title"}, :sharing=>{:use_whitelist=>"0", :user_blacklist=>"0", :sharing_scope =>Policy::ALL_SYSMO_USERS, "access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::NO_ACCESS}
    assert_redirected_to model_path(model)
    model.reload
    assert_equal "new title", model.title
    assert_equal Policy::NO_ACCESS, model.policy.access_type, "policy should have been updated"
  end

  test "owner should be able to choose policy 'share with everyone' when creating a model" do
    model={ :title=>"Test",:project_ids=>[projects(:moses_project).id]}
    post :create, :model => model,:content_blob=>{:data_0=>file_for_upload}, :sharing=>{:use_whitelist=>"0", :user_blacklist=>"0", :sharing_scope =>Policy::EVERYONE, "access_type_#{Policy::EVERYONE}"=>Policy::VISIBLE}
    assert_redirected_to model_path(assigns(:model))
    assert_equal users(:model_owner),assigns(:model).contributor
    assert assigns(:model)

    model=assigns(:model)
    assert_equal Policy::EVERYONE,model.policy.sharing_scope
    assert_equal Policy::VISIBLE,model.policy.access_type
    #check it doesn't create an error when retreiving the index
    get :index
    assert_response :success
  end

  test "owner should be able to choose policy 'share with everyone' when updating a model" do
    login_as(:model_owner)
    user = users(:model_owner)
    model = Factory(:model, :contributor => user)
    assert model.can_edit?(user), "model should be editable and manageable for this test"
    assert model.can_manage?(user), "model should be editable and manageable for this test"
    assert_equal Policy::NO_ACCESS, model.policy.access_type, "data file should have an initial policy with access type of no access"
    put :update, :id => model, :model => {:title=>"new title"}, :sharing=>{:use_whitelist=>"0", :user_blacklist=>"0", :sharing_scope =>Policy::EVERYONE, "access_type_#{Policy::EVERYONE}"=>Policy::VISIBLE}
    assert_redirected_to model_path(model)
    model.reload

    assert_equal "new title", model.title
    assert_equal Policy::EVERYONE, model.policy.sharing_scope, "policy should have been changed to everyone"
    assert_equal Policy::VISIBLE, model.policy.access_type, "policy should have been updated to visible"
  end

  test "update with ajax only applied when viewable" do
    p=Factory :person
    p2=Factory :person
    viewable_model=Factory :model,:contributor=>p2,:policy=>Factory(:publicly_viewable_policy)
    dummy_model=Factory :model

    login_as p.user

    assert viewable_model.can_view?(p.user)
    assert !viewable_model.can_edit?(p.user)

    golf=Factory :tag,:annotatable=>dummy_model,:source=>p2,:value=>"golf"

    xml_http_request :post, :update_annotations_ajax,{:id=>viewable_model,:tag_autocompleter_unrecognized_items=>[],:tag_autocompleter_selected_ids=>[golf.value.id]}

    viewable_model.reload

    assert_equal ["golf"],viewable_model.annotations.collect{|a| a.value.text}

    private_model=Factory :model,:contributor=>p2,:policy=>Factory(:private_policy)

    assert !private_model.can_view?(p.user)
    assert !private_model.can_edit?(p.user)

    xml_http_request :post, :update_annotations_ajax,{:id=>private_model,:tag_autocompleter_unrecognized_items=>[],:tag_autocompleter_selected_ids=>[golf.value.id]}

    private_model.reload
    assert private_model.annotations.empty?

  end

  test "update tags with ajax" do
    p = Factory :person

    login_as p.user

    p2 = Factory :person
    model = Factory :model,:contributor=>p.user


    assert model.annotations.empty?,"this model should have no tags for the test"

    golf = Factory :tag,:annotatable=>model,:source=>p2.user,:value=>"golf"
    Factory :tag,:annotatable=>model,:source=>p2.user,:value=>"sparrow"

    model.reload

    assert_equal ["golf","sparrow"],model.annotations.collect{|a| a.value.text}.sort
    assert_equal [],model.annotations.select{|a| a.source==p.user}.collect{|a| a.value.text}.sort
    assert_equal ["golf","sparrow"],model.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

    xml_http_request :post, :update_annotations_ajax,{:id=>model,:tag_autocompleter_unrecognized_items=>["soup"],:tag_autocompleter_selected_ids=>[golf.value.id]}

    model.reload

    assert_equal ["golf","soup","sparrow"],model.annotations.collect{|a| a.value.text}.uniq.sort
    assert_equal ["golf","soup"],model.annotations.select{|a| a.source==p.user}.collect{|a| a.value.text}.sort
    assert_equal ["golf","sparrow"],model.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

  end

  test "do publish" do
    model=models(:teusink_with_project_without_gatekeeper)
    assert model.can_manage?,"The sop must be manageable for this test to succeed"
    post :publish,:id=>model
    assert_response :redirect
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
  end

  test "do not publish if not can_manage?" do
    login_as(:quentin)
    model=models(:teusink_with_project_without_gatekeeper)
    assert !model.can_manage?,"The sop must not be manageable for this test to succeed"
    post :publish,:id=>model
    assert_redirected_to :root
    assert_not_nil flash[:error]
    assert_nil flash[:notice]
  end

  test "removing an asset should not break show pages for items that have attribution relationships referencing it" do
    model = Factory :model, :contributor => User.current_user
    disable_authorization_checks do
      attribution = Factory :model
      model.relationships.create :other_object => attribution, :predicate => Relationship::ATTRIBUTED_TO
      model.save!
      attribution.destroy
    end

    get :show, :id => model.id
    assert_response :success

    model.reload
    assert model.relationships.empty?
  end

  test "should set the other creators " do
    model=models(:teusink)
    assert model.can_manage?,"The sop must be manageable for this test to succeed"
    put :update, :id => model, :model => {:other_creators => 'marry queen'}
    model.reload
    assert_equal 'marry queen', model.other_creators
  end

  test 'should show the other creators on the model index' do
    model=models(:teusink)
    model.other_creators = 'another creator'
    model.save
    get :index

    assert_select 'p.list_item_attribute', :text => /: another creator/, :count => 1
  end

  test "should display cytoscape button for supported models" do
    model = Factory :xgmml_model
    login_as(model.contributor)
    get :show, :id=>model.id
    assert_response :success
    assert_select "a[href=?]",visualise_model_path(model,:version=>model.version), :text=>"Visualise #{I18n.t('model')} with Cytoscape Web"
  end

  test "should not display cytoscape button for supported models" do
    model = Factory :teusink_jws_model
    login_as(model.contributor)
    get :show, :id=>model.id
    assert_response :success
    assert_select "a[href=?]",visualise_model_path(model,:version=>model.version), :count=>0
  end

  test "visualise with cytoscape" do
    model = Factory :xgmml_model
    login_as(model.contributor)
    get :visualise, :id=>model.id,:version=>model.version
    assert_response :success
  end

  test "should show sycamore button for sbml" do
    with_config_value :sycamore_enabled,true do
      model = Factory :teusink_model
      login_as(model.contributor)
      get :show, :id=>model.id
      assert_response :success
      assert_select "a", :text => /Simulate #{I18n.t('model')} on Sycamore/
    end
  end

  test "should submit_to_sycamore" do
    with_config_value :sycamore_enabled,true do
      model = Factory :teusink_model
      login_as(model.contributor)
      post :submit_to_sycamore, :id=>model.id, :version => model.version
      assert_response :success
      assert @response.body.include?('$("sycamore-form").submit()')
    end
  end

  test "should not submit_to_sycamore if sycamore is disable" do
    with_config_value :sycamore_enabled,false do
      model = Factory :teusink_model
      login_as(model.contributor)
      post :submit_to_sycamore, :id => model.id, :version => model.version
      assert @response.body.include?('Interaction with Sycamore is currently disabled')
    end
  end

  test "should not submit_to_sycamore if model is not downloadable" do
    with_config_value :sycamore_enabled,true do
      model = Factory :teusink_model
      login_as(:quentin)
      assert !model.can_download?

      post :submit_to_sycamore, :id => model.id, :version => model.version
      assert @response.body.include?("You are not allowed to simulate this #{I18n.t('model')} with Sycamore")
    end
  end

  test 'should show the other creators in uploader and creators box' do
    model=models(:teusink)
    model.other_creators = 'another creator'
    model.save
    get :show, :id => model

    assert_select 'div', :text => /another creator/, :count => 1
  end

  test "should create new model version based on content_blobs of previous version" do
    m = Factory(:model_2_files, :policy => Factory(:private_policy))
    retained_content_blob = m.content_blobs.first
    login_as(m.contributor)
    assert_difference("Model::Version.count", 1) do
      post :new_version, :id=>m, :model=>{},:content_blob=>{:data_0=>file_for_upload}, :content_blobs=> {:id => {"#{retained_content_blob.id}" => retained_content_blob.original_filename}}
    end

    assert_redirected_to model_path(m)
    assert assigns(:model)

    m=Model.find(m.id)
    assert_equal 2,m.versions.size
    assert_equal 2,m.version
    content_blobs = m.content_blobs
    assert_equal 2,content_blobs.size
    assert !content_blobs.include?(retained_content_blob)
    assert content_blobs.collect(&:original_filename).include?(retained_content_blob.original_filename)
  end

  test "should display find matching data button for sbml model" do
    with_config_value :solr_enabled,true do
      m = Factory(:teusink_model)
      login_as(m.contributor.user)
      get :show,:id=>m
      assert_response :success
      assert_select "ul.sectionIcons span.icon > a[href=?]",matching_data_model_path(m),:text=>/Find related #{I18n.t('data_file').pluralize}/
    end
  end

  test "should display find matching data button for jws dat model" do
    with_config_value :solr_enabled,true do
      m = Factory(:teusink_jws_model)
      login_as(m.contributor.user)
      get :show,:id=>m
      assert_response :success
      assert_select "ul.sectionIcons span.icon > a[href=?]",matching_data_model_path(m),:text=>/Find related #{I18n.t('data_file').pluralize}/
    end
  end

  test "should not display find matching data button for non smbml or dat model" do
    with_config_value :solr_enabled,true do
      m = Factory(:non_sbml_xml_model)
      login_as(m.contributor.user)
      get :show,:id=>m
      assert_response :success
      assert_select "ul.sectionIcons span.icon > a[href=?]",matching_data_model_path(m),:count=>0
      assert_select "ul.sectionIcons span.icon > a",:text=>/Find related #{I18n.t('data_file').pluralize}/,:count=>0
    end
  end

  test "only show the matching data button for the latest version" do
    m = Factory(:teusink_jws_model, :policy => Factory(:public_policy))

    m.save_as_new_version
    Factory(:teusink_jws_model_content_blob, :asset => m, :asset_version => m.version)
    m.reload
    login_as(m.contributor.user)
    assert_equal 2,m.version
    with_config_value :solr_enabled,true do
      get :show,:id=>m,:version=>2
      assert_response :success
      assert_select "ul.sectionIcons span.icon > a",:text=>/Find related #{I18n.t('data_file').pluralize}/
      assert_select "ul.sectionIcons span.icon > a[href=?]",matching_data_model_path(m),:text=>/Find related #{I18n.t('data_file').pluralize}/

      get :show,:id=>m,:version=>1
      assert_response :success
      assert_select "ul.sectionIcons span.icon > a[href=?]",matching_data_model_path(m),:count=>0
      assert_select "ul.sectionIcons span.icon > a",:text=>/Find related #{I18n.t('data_file').pluralize}/,:count=>0
    end
  end

  test "should have -View content- button on the model containing one inline viewable file" do
    one_file_model = Factory(:doc_model, :policy => Factory(:all_sysmo_downloadable_policy))
    assert_equal 1, one_file_model.content_blobs.count
    assert one_file_model.content_blobs.first.is_content_viewable?
    get :show, :id => one_file_model.id
    assert_response :success
    assert_select 'a', :text => /View content/, :count => 1

    multiple_files_model = Factory(:model,
                                   :content_blobs => [Factory(:doc_content_blob), Factory(:content_blob)],
                                   :policy => Factory(:all_sysmo_downloadable_policy))
    assert_equal 2, multiple_files_model.content_blobs.count
    assert multiple_files_model.content_blobs.first.is_content_viewable?
    get :show, :id => multiple_files_model.id
    assert_response :success
    assert_select 'a', :text => /View content/, :count => 0
  end

  test "compare versions" do
    #just compares with itself for now
    model = Factory :model,:contributor=>User.current_user.person
    assert model.contains_sbml?,"model should contain sbml"
    assert model.can_download?,"should be able to download"

    get :compare_versions,:id=>model,:other_version=>model.versions.last.version
    assert_response :success
    assert_select "div.bives_output ul li",:text=>/Both documents have same Level\/Version:/,:count=>1
  end

  test "cannot compare versions if you cannot download" do
    model = Factory(:model,:contributor=>Factory(:person),:policy=>Factory(:publicly_viewable_policy))
    assert model.can_view?, "should be able to view this model"
    assert !model.can_download?, "should not be able to download this model"
    get :compare_versions,:id=>model,:other_version=>model.versions.last.version
    assert_response :redirect
    refute_nil flash[:error]
  end

  test "compare versions option on page" do
    p  = Factory(:person)
    login_as(p)

    model = Factory(:teusink_model,:contributor=>p,:policy=>Factory(:public_policy))
    model.save_as_new_version
    Factory(:cronwright_model_content_blob,:asset_version=>model.version,:asset=>model)
    model.reload
    assert_equal 2,model.version
    assert model.can_download?
    assert_equal 2, model.versions.select{|v| v.contains_sbml?}.count
    get :show,:id=>model
    assert_response :success

    assert_select "select#compare_versions",:count=>1 do
      assert_select "option[value=?]",compare_versions_model_path(model,:other_version=>1,:version=>2)
    end
  end

  test "compare versions option not shown when not downloadable" do
    p  = Factory(:person)
    login_as(Factory(:person))
    model = Factory(:teusink_model,:contributor=>p,:policy=>Factory(:publicly_viewable_policy))
    disable_authorization_checks do
      model.save_as_new_version
      Factory(:cronwright_model_content_blob,:asset_version=>model.version,:asset=>model)
    end

    model.reload
    assert_equal 2,model.version
    refute model.can_download?

    assert_equal 2, model.versions.select{|v| v.contains_sbml?}.count
    get :show,:id=>model
    assert_response :success

    assert_select "select#compare_versions",:count=>0
  end


  test "gracefully handle error when other version missing" do
    model = Factory :model,:contributor=>User.current_user.person
    assert model.contains_sbml?,"model should contain sbml"
    assert model.can_download?,"should be able to download"

    get :compare_versions,:id=>model
    assert_redirected_to model_path(model,:version=>model.version)
    refute_nil flash[:error]
  end

  test "should show SBML format for model that contains sbml and format not specified" do
    model = Factory(:teusink_model,:policy=>Factory(:public_policy),:model_format=>nil)
    assert model.contains_sbml?
    get :show, :id=>model.id
    assert_response :success
    assert_select "#format_info" do
      assert_select "#model_format",:text=>/SBML/i
    end
  end

  def valid_model
    { :title=>"Test",:project_ids=>[projects(:sysmo_project).id]}
  end

  def valid_model_with_url
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png","http://www.sysmo-db.org/images/sysmo-db-logo-grad2.png"
    return { :title=>"Test",:project_ids=>[projects(:sysmo_project).id]},{:data_url_0=>"http://www.sysmo-db.org/images/sysmo-db-logo-grad2.png",:original_filename_0=>"sysmo-db-logo-grad2.png",:make_local_copy_0=>"0"}
  end
  
end
