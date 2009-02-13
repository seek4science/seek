require File.dirname(__FILE__) + '/../test_helper'

class PeopleControllerTest < ActionController::TestCase
  
  fixtures :people, :users
  
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
    assert_not_nil assigns(:people)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_person
    assert_difference('Person.count') do
      post :create, :person => {:first_name=>"test",:email=>"test@test.com" }
    end

    assert_redirected_to person_path(assigns(:person))
  end

  def test_should_show_person
    get :show, :id => people(:one).id
    assert_response :success
  end
  
  def test_show_no_email
      get :show, :id => people(:one).id
      assert_select "span.none_text", :text=>"Not specified"
  end

  def test_should_get_edit
    get :edit, :id => people(:one).id
    assert_response :success
  end
  
  def test_non_admin_cant_edit_someone_else
    login_as(:fred)
    get :edit, :id=> people(:two).id
    assert_redirected_to root_path
  end

  def test_admin_can_edit_others
    get :edit, :id=>people(:two).id
    assert_response :success
  end
  
  def test_can_edit_person_and_user_id_different
    #where a user_id for a person are not the same
    login_as(:fred)
    get :edit, :id=>people(:fred).id
    assert_response :success
  end
  
  def test_not_current_user_doesnt_show_link_to_change_password
      get :edit, :id => people(:two).id
      assert_select "a", :text=>"Change login details", :count=>0  
  end
  
  def test_current_user_does_show_link_to_change_password
      get :edit, :id => people(:one).id
      assert_select "a", :text=>"Change login details", :count=>1   
  end

  def test_should_update_person
    put :update, :id => people(:one).id, :person => { }
    assert_redirected_to person_path(assigns(:person))
  end

  def test_should_destroy_person
    assert_difference('Person.count', -1) do
      delete :destroy, :id => people(:one).id
    end

    assert_redirected_to people_path
  end
end
