require 'test_helper'
require 'libxml'
require 'rest_test_cases'

class ProjectsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include RestTestCases
  
  fixtures :all
  
  def test_title
    get :index
    assert_select "title",:text=>/Sysmo SEEK.*/, :count=>1
  end
  
  def setup
    login_as(:quentin)
    @object=projects(:sysmo_project)
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


  test "non admin cannot administer project" do
    login_as(:pal_user)
    get :admin,:id=>projects(:sysmo_project)
    assert_response :redirect
    assert_not_nil flash[:error]
  end
  
  test "admin can administer project" do    
    get :admin,:id=>projects(:sysmo_project)
    assert_response :success
    assert_nil flash[:error]
  end

  test "non admin has no option to administer project" do
    login_as(:pal_user)
    get :show,:id=>projects(:sysmo_project)
    assert_select "ul.sectionIcons" do
      assert_select "span.icon" do
        assert_select "a[href=?]",admin_project_path(projects(:sysmo_project)),:text=>/Project administration/,:count=>0
      end
    end
  end

  test "admin has option to administer project" do
    get :show,:id=>projects(:sysmo_project)
    assert_select "ul.sectionIcons" do
      assert_select "span.icon" do
        assert_select "a[href=?]",admin_project_path(projects(:sysmo_project)),:text=>/Project administration/,:count=>1
      end
    end
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
