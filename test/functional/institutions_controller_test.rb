require File.dirname(__FILE__) + '/../test_helper'

class InstitutionsControllerTest < ActionController::TestCase
 
  
  fixtures :institutions, :users, :people, :work_groups, :group_memberships
  
  include AuthenticatedTestHelper
  
  def setup
    login_as(:quentin)
  end

  def test_title
    get :index
    assert_select "title",:text=>/Sysmo SEEK.*/, :count=>1
  end
  
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:institutions)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_institution
    assert_difference('Institution.count') do
      post :create, :institution => {:name=>"test" }
    end

    assert_redirected_to institution_path(assigns(:institution))
  end

  def test_should_show_institution
    get :show, :id => institutions(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => institutions(:one).id
    assert_response :success
  end

  def test_should_update_institution
    put :update, :id => institutions(:one).id, :institution => { }
    assert_redirected_to institution_path(assigns(:institution))
  end

  def test_should_destroy_institution
    assert_difference('Institution.count', -1) do
      delete :destroy, :id => institutions(:four).id
    end

    assert_redirected_to institutions_path
  end

  #Checks that the edit option is availabe to the user
  #with can_edit_project set and he belongs to that project
  def test_user_can_edit
    login_as(:can_edit)
    get :show, :id=>institutions(:two)
    assert_select "a",:text=>/Edit Institution/,:count=>1

    get :edit, :id=>institutions(:two)
    assert_response :success

    put :update, :id=>institutions(:two).id,:institution=>{}
    assert_redirected_to institution_path(assigns(:institution))
  end

  def test_user_cant_edit_project
    login_as(:cant_edit)
    get :show, :id=>institutions(:two)
    assert_select "a",:text=>/Edit Institution/,:count=>0

    get :edit, :id=>institutions(:two)
    assert_response :redirect

    #TODO: Test for update
  end

  def test_admin_can_edit
    get :show, :id=>institutions(:two)
    assert_select "a",:text=>/Edit Institution/,:count=>1

    get :edit, :id=>institutions(:two)
    assert_response :success

    put :update, :id=>institutions(:two).id,:institution=>{}
    assert_redirected_to institution_path(assigns(:institution))
  end

end
