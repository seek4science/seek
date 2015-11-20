require 'test_helper'

class HelpDocumentsControllerTest < ActionController::TestCase

  fixtures :all
  
  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test "should be available to non logged in users for internal help" do
    logout
    with_config_value :internal_help_enabled, true do
      get :index
      assert_response :success
      assert_not_nil assigns(:help_documents)

      get :show, :id => help_documents(:one).to_param
      assert_response :success
      assert_not_nil assigns(:help_document)
    end
  end
  
  test "should be available to non logged in users for external help" do
    logout
    with_config_value :internal_help_enabled, false do
      get :index
      assert_response :redirect
    end
  end
  
  test "should get index" do
    with_config_value :internal_help_enabled, true do
      get :index
      assert_response :success
      assert_not_nil assigns(:help_documents)
    end
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create help_document" do
    with_config_value :internal_help_enabled, true do
      assert_difference('HelpDocument.count') do
        post :create, :help_document => { :identifier => "test", :title => "new" }
      end

      assert_redirected_to help_document_path(assigns(:help_document))
    end
  end

  test "should show help_document" do
    with_config_value :internal_help_enabled, true do
      get :show, :id => help_documents(:one).to_param
      assert_response :success
    end
  end

  test "should get edit" do
    with_config_value :internal_help_enabled, true do
      get :edit, :id => help_documents(:one).to_param
      assert_response :success
    end
  end

  test "should update help_document" do
    with_config_value :internal_help_enabled, true do
      put :update, :id => help_documents(:one).to_param, :help_document => {:title => "fish"}
      assert_redirected_to help_document_path(assigns(:help_document))
    end
  end

  test "should destroy help_document" do
    with_config_value :internal_help_enabled, true do
      assert_difference('HelpDocument.count', -1) do
        delete :destroy, :id => help_documents(:one).to_param
      end

      assert_redirected_to help_documents_path
    end
  end

  test "shouldn't allow non-admins to create" do
    with_config_value :internal_help_enabled, true do
      login_as(:aaron)
      get :new
      assert_response :redirect
      assert_not_nil flash[:error]
    end
  end

  test "shouldn't allow anonymous users to create" do
    with_config_value :internal_help_enabled, true do
      logout
      get :new
      assert_response :redirect
      assert_not_nil flash[:error]
    end
  end
  
  test "should redirect to index page if available" do
    with_config_value :internal_help_enabled, true do
      assert_difference('HelpDocument.count') do
        post :create, :help_document => { :identifier => "index", :title => "Index page" }
        get :index
        assert_response :redirect
        assert_nil assigns(:help_documents) #no collection set (not on index page)
        assert_not_nil assigns(:help_document) #doc set (on show page)
      end    
    end
  end
  
  test "can't change identifier" do
    with_config_value :internal_help_enabled, true do
      assert_no_difference('help_documents(:one).identifier.hash') do
        put :update, :id => help_documents(:one).to_param, :help_document => {:identifier => "fish"}
      end
    end 
  end

  test "shouldn't create docs with invalid identifiers" do
    with_config_value :internal_help_enabled, true do
      assert_no_difference('HelpDocument.count') do
        post :create, :help_document => { :identifier => "//#[][]a", :title => "invalid1" }
        post :create, :help_document => { :identifier => "hello/hello", :title => "invalid2" }
        post :create, :help_document => { :identifier => "-hello", :title => "invalid3" }
      end
    end 
  end
end
