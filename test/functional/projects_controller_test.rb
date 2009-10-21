require File.dirname(__FILE__) + '/../test_helper'

class ProjectsControllerTest < ActionController::TestCase
  
  fixtures :all
  
  def test_title
    get :index
    assert_select "title",:text=>/Sysmo SEEK.*/, :count=>1
  end

  include AuthenticatedTestHelper
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
    assert_select "a",:text=>/\[Change\]/,:count=>1

    get :edit, :id=>projects(:three)
    assert_response :success

    put :update, :id=>projects(:three).id,:project=>{}
    assert_redirected_to project_path(assigns(:project))
  end

  def test_user_cant_edit_project
    login_as(:cant_edit)
    get :show, :id=>projects(:three)
    assert_select "a",:text=>/Edit Project/,:count=>0
    assert_select "a",:text=>/\[Change\]/,:count=>0

    get :edit, :id=>projects(:three)
    assert_response :redirect

    #TODO: Test for update
  end

  def test_admin_can_edit
    get :show, :id=>projects(:one)
    assert_select "a",:text=>/Edit Project/,:count=>1
    assert_select "a",:text=>/\[Change\]/,:count=>1

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
    assert_select "table.list_item div.desc" do
      assert_select "a[rel=?]","nofollow",:text=>/news\.bbc\.co\.uk/,:minimum=>1
    end
  end

  test "links have nofollow in data_files tabs" do
    login_as(:owner_of_my_first_sop)
    data_file=data_files(:picture)
    data_file.description="http://news.bbc.co.uk"
    data_file.save!

    get :show,:id=>projects(:sysmo_project)
    assert_select "table.list_item div.desc" do
      assert_select "a[rel=?]","nofollow",:text=>/news\.bbc\.co\.uk/,:minimum=>1
    end
  end

  test "links have nofollow in model tabs" do
    login_as(:owner_of_my_first_sop)
    model=models(:teusink)
    model.description="http://news.bbc.co.uk"
    model.save!

    get :show,:id=>projects(:sysmo_project)
    assert_select "table.list_item div.desc" do
      assert_select "a[rel=?]","nofollow",:text=>/news\.bbc\.co\.uk/,:minimum=>1
    end
  end

  private

  def valid_project
    return {}
  end
end
