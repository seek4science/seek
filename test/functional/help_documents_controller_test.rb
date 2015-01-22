require 'test_helper'

class HelpDocumentsControllerTest < ActionController::TestCase

  fixtures :all
  
  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test "should be available to non logged in users" do
    logout
    get :index
    assert_response :success
    assert_not_nil assigns(:help_documents)

    get :show, :id => help_documents(:one).to_param
    assert_response :success
    assert_not_nil assigns(:help_document)
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:help_documents)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create help_document" do
    assert_difference('HelpDocument.count') do
      post :create, :help_document => { :identifier => "test", :title => "new" }
    end

    assert_redirected_to help_document_path(assigns(:help_document))
  end

  test "should show help_document" do
    get :show, :id => help_documents(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => help_documents(:one).to_param
    assert_response :success
  end

  test "should update help_document" do
    put :update, :id => help_documents(:one).to_param, :help_document => {:title => "fish"}
    assert_redirected_to help_document_path(assigns(:help_document))
  end

  test "should destroy help_document" do
    assert_difference('HelpDocument.count', -1) do
      delete :destroy, :id => help_documents(:one).to_param
    end

    assert_redirected_to help_documents_path
  end
  
  test "shouldn't allow non-admins to create" do
    login_as(:aaron)
    get :new
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test "shouldn't allow anonymous users to create" do
    logout
    get :new
    assert_response :redirect
    assert_not_nil flash[:error]
  end
  
  test "should redirect to index page if available" do
    assert_difference('HelpDocument.count') do
      post :create, :help_document => { :identifier => "index", :title => "Index page" }
      get :index
      assert_response :redirect
      assert_nil assigns(:help_documents) #no collection set (not on index page)
      assert_not_nil assigns(:help_document) #doc set (on show page)
    end    
  end
  
  test "can't change identifier" do
    assert_no_difference('help_documents(:one).identifier.hash') do
      put :update, :id => help_documents(:one).to_param, :help_document => {:identifier => "fish"}
    end
  end 
  
  test "shouldn't create docs with invalid identifiers" do
    assert_no_difference('HelpDocument.count') do
      post :create, :help_document => { :identifier => "//#[][]a", :title => "invalid1" }
      post :create, :help_document => { :identifier => "hello/hello", :title => "invalid2" }
      post :create, :help_document => { :identifier => "-hello", :title => "invalid3" }
    end
  end 
end
