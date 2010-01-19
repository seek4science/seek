require File.dirname(__FILE__) + '/../test_helper'
require 'libxml'

class ProjectsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  
  fixtures :all
  
  def test_title
    get :index
    assert_select "title",:text=>/Sysmo SEEK.*/, :count=>1
  end
  
  def setup
    login_as(:quentin)
  end
  
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:projects)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_project
    assert_difference('Project.count') do
      post :create, :project => {:name=>"test"}
    end

    assert_redirected_to project_path(assigns(:project))
  end

  def test_should_show_project
    get :show, :id => projects(:four)
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => projects(:four)
    assert_response :success
  end

  def test_should_update_project
    put :update, :id => projects(:four), :project => valid_project
    assert_redirected_to project_path(assigns(:project))
  end

  def test_should_destroy_project
    assert_difference('Project.count', -1) do
      delete :destroy, :id => projects(:four)
    end

    assert_redirected_to projects_path
  end

  def test_non_admin_should_not_destroy_project
    login_as(:aaron)
    assert_no_difference('Project.count') do
      delete :destroy, :id => projects(:four)
    end
    
  end


  #Checks that the edit option is availabe to the user
  #with can_edit_project set and he belongs to that project
  def test_user_can_edit_project
    login_as(:can_edit)
    get :show, :id=>projects(:three)
    assert_select "a",:text=>/Edit Project/,:count=>1    

    get :edit, :id=>projects(:three)
    assert_response :success

    put :update, :id=>projects(:three).id,:project=>{}
    assert_redirected_to project_path(assigns(:project))
  end

  def test_user_cant_edit_project
    login_as(:cant_edit)
    get :show, :id=>projects(:three)
    assert_select "a",:text=>/Edit Project/,:count=>0    

    get :edit, :id=>projects(:three)
    assert_response :redirect

    #TODO: Test for update
  end

  def test_admin_can_edit
    get :show, :id=>projects(:one)
    assert_select "a",:text=>/Edit Project/,:count=>1    

    get :edit, :id=>projects(:one)
    assert_response :success

    put :update, :id=>projects(:three).id,:project=>{}
    assert_redirected_to project_path(assigns(:project))
  end

  test "links have nofollow in sop tabs" do
    login_as(:owner_of_my_first_sop)
    sop=sops(:my_first_sop)
    sop.description="http://news.bbc.co.uk"
    sop.save!

    get :show,:id=>projects(:sysmo_project)
    assert_select "div.list_item div.list_item_desc" do
      assert_select "a[rel=?]","nofollow",:text=>/news\.bbc\.co\.uk/,:minimum=>1
    end
  end

  test "links have nofollow in data_files tabs" do
    login_as(:owner_of_my_first_sop)
    data_file=data_files(:picture)
    data_file.description="http://news.bbc.co.uk"
    data_file.save!

    get :show,:id=>projects(:sysmo_project)
    assert_select "div.list_item div.list_item_desc" do
      assert_select "a[rel=?]","nofollow",:text=>/news\.bbc\.co\.uk/,:minimum=>1
    end
  end

  test "links have nofollow in model tabs" do
    login_as(:owner_of_my_first_sop)
    model=models(:teusink)
    model.description="http://news.bbc.co.uk"
    model.save!

    get :show,:id=>projects(:sysmo_project)
    assert_select "div.list_item div.list_item_desc" do
      assert_select "a[rel=?]","nofollow",:text=>/news\.bbc\.co\.uk/,:minimum=>1
    end
  end

  test "pals displayed in show page" do
    get :show,:id=>projects(:sysmo_project)
    assert_select "div.box_about_actor p.pals" do
      assert_select "label",:text=>"SysMO-DB Pals:",:count=>1
      assert_select "a",:count=>1
      assert_select "a[href=?]",person_path(people(:pal)),:text=>"A Pal",:count=>1
    end
  end

  test "no pals displayed for project with no pals" do
    get :show,:id=>projects(:myexperiment_project)
    assert_select "div.box_about_actor p.pals" do
      assert_select "label",:text=>"SysMO-DB Pals:",:count=>1
      assert_select "a",:count=>0
      assert_select "span.none_text",:text=>"No Pals for this project",:count=>1
    end
  end

  test "admin can edit institutions" do
    #quentin is an admin
    get :edit, :id=>projects(:sysmo_project)
    assert_response :success
    assert_select "h2",:text=>"Participating Institutions",:count=>1
    assert_select "select#project_institution_ids",:count=>1
  end

  test "non admin cannnot edit institutions" do
    login_as(:pal_user)
    get :edit, :id=>projects(:sysmo_project)
    assert_response :success
    assert_select "h2",:text=>"Participating Institutions",:count=>0
    assert_select "select#project_institution_ids",:count=>0
  end

  test "admins can edit credentials" do
    get :edit, :id=>projects(:sysmo_project)
    assert_response :success
    assert_select "h2",:text=>"Remote site details",:count=>1
    assert_select "input#project_site_username",:count=>1
    assert_select "input[type='password']#project_site_password",:count=>1
  end

  test "non admins cannot edit credentials" do
    login_as(:pal_user)
    get :edit, :id=>projects(:sysmo_project)
    assert_response :success
    assert_select "h2",:text=>"Remote site details",:count=>0
    assert_select "input#project_site_username",:count=>0
    assert_select "input#project_site_password",:count=>0
    assert_select "input[type='password']#project_site_password",:count=>0
  end
  
  test "admins can edit site uri" do
    get :edit, :id=>projects(:sysmo_project)
    assert_response :success    
    assert_select "input#project_site_root_uri",:count=>1
  end

  test "non admins cannot edit site root uri" do
    login_as(:pal_user)
    get :edit, :id=>projects(:sysmo_project)
    assert_response :success
    assert_select "input#project_site_root_uri",:count=>0
  end

  test "site_credentials hidden from show xml" do
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :show, :id=>projects(:sysmo_project)
    assert_response :success    
    parser = LibXML::XML::Parser.string(@response.body,:encoding => LibXML::XML::Encoding::UTF_8)
    document = parser.parse
    assert !document.find("//name").empty?,"There should be a field 'name'"
    assert document.find("//site-credentials").empty?,"There should not be a field 'site-credentials'"
    assert document.find("//site-password").empty?,"There should not be a field 'site-username'"
    assert document.find("//site-username").empty?,"There should not be a field 'site-password'"
  end

  test "site_credentials hidden from index xml" do
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :index,:page=>"all"
    assert_response :success
    parser = LibXML::XML::Parser.string(@response.body,:encoding => LibXML::XML::Encoding::UTF_8)
    document = parser.parse    
    assert !document.find("//name").empty?,"There should be a field 'name'"
    assert document.find("//site-credentials").empty?,"There should not be a field 'site-credentials'"
    assert document.find("//site-password").empty?,"There should not be a field 'site-username'"
    assert document.find("//site-username").empty?,"There should not be a field 'site-password'"
  end

  test "site_root_uri hidden from index xml" do
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :index,:page=>"all"
    assert_response :success
    parser = LibXML::XML::Parser.string(@response.body,:encoding => LibXML::XML::Encoding::UTF_8)
    document = parser.parse
    assert !document.find("//name").empty?,"There should be a field 'name'"
    assert document.find("//site-root-uri").empty?,"There should not be a field 'site-root-uri'"
  end

  test "site_root_uri hidden from show xml" do
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :show, :id=>projects(:sysmo_project)
    assert_response :success
    parser = LibXML::XML::Parser.string(@response.body,:encoding => LibXML::XML::Encoding::UTF_8)
    document = parser.parse
    assert !document.find("//name").empty?,"There should be a field 'name'"
    assert document.find("//site-root-uri").empty?,"There should not be a field 'site-root-uri'"
  end
  
  test "default policy form hidden from non-admin" do
    login_as(:pal_user)
    get :edit, :id=>projects(:sysmo_project)
    assert_response :success #can see the edit page
    assert_select "input#cb_use_blacklist",:count=>0 #but not the default policy form
  end
  
  test "changing default policy" do
    login_as(:quentin)
    
    person = people(:two) #aaron
    project = projects(:four)
    assert_nil project.default_policy_id #check theres no policy to begin with
    
    #Set up the sharing param to share with one person (aaron)
    sharing = {}
    sharing[:permissions] = {}
    sharing[:permissions][:contributor_types] = ActiveSupport::JSON.encode(["Person"])
    sharing[:permissions][:values] = ActiveSupport::JSON.encode({"Person"=>{(person.id)=>{"access_type"=>0}}})                             
    sharing[:sharing_scope] = 1
    put :update, :id => project.id, :project => valid_project, :sharing => sharing

    project = Project.find(project.id)
    assert_redirected_to project
    assert project.default_policy_id
    assert Permission.find_by_policy_id(project.default_policy).contributor_id == person.id
  end

  private

  def valid_project
    return {}
  end
end
