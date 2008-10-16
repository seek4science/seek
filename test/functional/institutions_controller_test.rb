require 'test_helper'

class InstitutionsControllerTest < ActionController::TestCase
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
      post :create, :institution => { }
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
      delete :destroy, :id => institutions(:one).id
    end

    assert_redirected_to institutions_path
  end
end
