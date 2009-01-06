require File.dirname(__FILE__) + '/../test_helper'

class ProjectsControllerTest < ActionController::TestCase
  
  fixtures :projects, :people, :users
  
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
      post :create, :project => {:name=>"test" }
    end

    assert_redirected_to project_path(assigns(:project))
  end

  def test_should_show_project
    get :show, :id => projects(:four).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => projects(:four).id
    assert_response :success
  end

  def test_should_update_project
    put :update, :id => projects(:four).id, :project => { }
    assert_redirected_to project_path(assigns(:project))
  end

  def test_should_destroy_project
    assert_difference('Project.count', -1) do
      delete :destroy, :id => projects(:four).id
    end

    assert_redirected_to projects_path
  end
end
