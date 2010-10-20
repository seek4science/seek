require 'test_helper'

class ModelsControllerTest < ActionController::TestCase
  
  fixtures :all
  
  include AuthenticatedTestHelper
  include RestTestCases  
  
  def setup
    login_as(:model_owner)
    @object=models(:teusink)
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:models)
  end
  
  test "shouldn't show hidden items in index" do
    login_as(:aaron)
    get :index, :page => "all"
    assert_response :success
    assert_equal assigns(:models).sort_by(&:id), Authorization.authorize_collection("view", assigns(:models), users(:aaron)).sort_by(&:id), "models haven't been authorized properly"
  end
  
  test "should get new" do
    get :new    
    assert_response :success
  end    
  
  test "should correctly handle bad data url" do
    model={:title=>"Test",:data_url=>"http://sdfsdfkh.com/sdfsd.png"}
    assert_no_difference('Model.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :model => model, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash.now[:error]
  end
  
  test "should not create invalid model" do
    model={:title=>"Test"}
    assert_no_difference('Model.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :model => model, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash.now[:error]
  end
  
  test "should create model" do
    assert_difference('Model.count') do
      post :create, :model => valid_model, :sharing=>valid_sharing
    end
    
    assert_redirected_to model_path(assigns(:model))
  end
  
  test "should create model with url" do
    assert_difference('Model.count') do
      assert_difference('ContentBlob.count') do
        post :create, :model => valid_model_with_url, :sharing=>valid_sharing
      end
    end
    assert_redirected_to model_path(assigns(:model))
    assert_equal users(:model_owner),assigns(:model).contributor   
    assert !assigns(:model).content_blob.url.blank?
    assert assigns(:model).content_blob.data.nil?
    assert !assigns(:model).content_blob.file_exists?
    assert_equal "sysmo-db-logo-grad2.png", assigns(:model).original_filename
    assert_equal "image/png", assigns(:model).content_type
  end
  
  test "should create sop and store with url and store flag" do
    model_details=valid_model_with_url
    model_details[:local_copy]="1"
    assert_difference('Model.count') do
      assert_difference('ContentBlob.count') do
        post :create, :model => model_details, :sharing=>valid_sharing
      end
    end
    assert_redirected_to model_path(assigns(:model))
    assert_equal users(:model_owner),assigns(:model).contributor
    assert !assigns(:model).content_blob.url.blank?
    assert !assigns(:model).content_blob.data.nil?
    assert assigns(:model).content_blob.file_exists?
    assert_equal "sysmo-db-logo-grad2.png", assigns(:model).original_filename
    assert_equal "image/png", assigns(:model).content_type
  end  
  
  test "should create with preferred environment" do
    assert_difference('Model.count') do
      model=valid_model
      model[:recommended_environment_id]=recommended_model_environments(:jws).id
      post :create, :model => model, :sharing=>valid_sharing
    end
    
    m=assigns(:model)
    assert m
    assert_equal "JWS Online",m.recommended_environment.title
  end
  
  test "should show model" do
    m = models(:teusink)
    m.save
    get :show, :id => m
    assert_response :success
  end
  
  test "should show model with format and type" do
    m = models(:model_with_format_and_type)
    m.save
    get :show, :id => m
    assert_response :success
  end
  
  test "should get edit" do
    get :edit, :id => models(:teusink).id
    assert_response :success
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
  
  test "should add model type" do
    login_as(:quentin)
    assert_difference('ModelType.count',1) do
      post :create_model_metadata, :attribute=>"model_type",:model_type=>"fred"
    end
    
    assert_response :success
    assert_not_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should add model type as pal" do
    login_as(:pal_user)
    assert_difference('ModelType.count',1) do
      post :create_model_metadata, :attribute=>"model_type",:model_type=>"fred"
    end
    
    assert_response :success
    assert_not_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should not add model type as non pal" do
    login_as(:aaron)
    assert_no_difference('ModelType.count') do
      post :create_model_metadata, :attribute=>"model_type",:model_type=>"fred"
    end
    
    assert_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should not add duplicate model type" do
    login_as(:quentin)
    m=model_types(:ODE)
    assert_no_difference('ModelType.count') do
      post :create_model_metadata, :attribute=>"model_type",:model_type=>m.title
    end
    
  end
  
  test "should add model format" do
    login_as(:quentin)
    assert_difference('ModelFormat.count',1) do
      post :create_model_metadata, :attribute=>"model_format",:model_format=>"fred"
    end
    
    assert_response :success
    assert_not_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should add model format as pal" do
    login_as(:pal_user)
    assert_difference('ModelFormat.count',1) do
      post :create_model_metadata, :attribute=>"model_format",:model_format=>"fred"
    end
    
    assert_response :success
    assert_not_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should not add model format as non pal" do
    login_as(:aaron)
    assert_no_difference('ModelFormat.count') do
      post :create_model_metadata, :attribute=>"model_format",:model_format=>"fred"
    end
    
    assert_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should not add duplicate model format" do
    login_as(:quentin)
    m=model_formats(:SBML)
    assert_no_difference('ModelFormat.count') do
      post :create_model_metadata, :attribute=>"model_format",:model_format=>m.title
    end
    
  end
  
  test "should update model format" do
    login_as(:quentin)
    m=model_formats(:SBML)
    
    assert_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_format",:updated_model_format=>"fred",:updated_model_format_id=>m.id
    end
    
    assert_not_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
  end
  
  test "should update model format as pal" do
    login_as(:pal_user)
    m=model_formats(:SBML)
    
    assert_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_format",:updated_model_format=>"fred",:updated_model_format_id=>m.id
    end
    
    assert_not_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
  end
  
  test "should not update model format as non pal" do
    login_as(:aaron)
    m=model_formats(:SBML)
    
    assert_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_format",:updated_model_format=>"fred",:updated_model_format_id=>m.id
    end
    
    assert_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
  end
  
  test "should update model type" do
    login_as(:quentin)
    m=model_types(:ODE)
    
    assert_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_type",:updated_model_type=>"fred",:updated_model_type_id=>m.id
    end
    
    assert_not_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
  end
  
  test "should update model type as pal" do
    login_as(:pal_user)
    m=model_types(:ODE)
    
    assert_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_type",:updated_model_type=>"fred",:updated_model_type_id=>m.id
    end
    
    assert_not_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
  end
  
  test "should not update model type as non pal" do
    login_as(:aaron)
    m=model_types(:ODE)
    
    assert_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_type",:updated_model_type=>"fred",:updated_model_type_id=>m.id
    end
    
    assert_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
  end
  
  def test_should_show_version
    m = models(:model_with_format_and_type)
    m.save! #to force creation of initial version (fixtures don't include it)
    old_desc=m.description
    old_desc_regexp=Regexp.new(old_desc)
    
    #create new version
    m.description="This is now version 2"
    assert m.save_as_new_version
    m = Model.find(m.id)
    assert_equal 2, m.versions.size
    assert_equal 2, m.version
    assert_equal 1, m.versions[0].version
    assert_equal 2, m.versions[1].version
    
    get :show, :id=>models(:model_with_format_and_type)
    assert_select "p", :text=>/This is now version 2/, :count=>1
    assert_select "p", :text=>old_desc_regexp, :count=>0
    
    get :show, :id=>models(:model_with_format_and_type), :version=>"2"
    assert_select "p", :text=>/This is now version 2/, :count=>1
    assert_select "p", :text=>old_desc_regexp, :count=>0
    
    get :show, :id=>models(:model_with_format_and_type), :version=>"1"
    assert_select "p", :text=>/This is now version 2/, :count=>0
    assert_select "p", :text=>old_desc_regexp, :count=>1
    
  end
  
  def test_should_create_new_version
    m=models(:model_with_format_and_type)    
    
    assert_difference("Model::Version.count", 1) do
      post :new_version, :id=>m, :model=>{:data=>fixture_file_upload('files/file_picture.png')}, :revision_comment=>"This is a new revision"
    end
    
    assert_redirected_to model_path(m)
    assert assigns(:model)
    assert_not_nil flash[:notice]
    assert_nil flash[:error]
    
    
    m=Model.find(m.id)
    assert_equal 2,m.versions.size
    assert_equal 2,m.version
    assert_equal "file_picture.png",m.original_filename
    assert_equal "file_picture.png",m.versions[1].original_filename
    assert_equal "Teusink.xml",m.versions[0].original_filename
    assert_equal "This is a new revision",m.versions[1].revision_comments
    
  end
  
  def valid_model
    { :title=>"Test",:data=>fixture_file_upload('files/little_file.txt')}
  end
  
  def valid_model_with_url
    { :title=>"Test",:data_url=>"http://www.sysmo-db.org/images/sysmo-db-logo-grad2.png"}
  end
  
  def valid_sharing
    {
      :use_whitelist=>"0",
      :user_blacklist=>"0",
      :sharing_scope=>Policy::ALL_REGISTERED_USERS,
      :permissions=>{:contributor_types=>ActiveSupport::JSON.encode("Person"),:values=>ActiveSupport::JSON.encode({})}
    }
  end
  
  def test_should_add_nofollow_to_links_in_show_page
    get :show, :id=> models(:model_with_links_in_description)    
    assert_select "div#description" do
      assert_select "a[rel=nofollow]"
    end
  end
  
  def test_update_should_not_overright_contributor
    login_as(:pal_user) #this user is a member of sysmo, and can edit this model
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
  
end
