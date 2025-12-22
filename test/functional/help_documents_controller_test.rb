require 'test_helper'

class HelpDocumentsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test 'should be available to non logged in users for internal help' do
    logout
    with_config_value :internal_help_enabled, true do
      get :index
      assert_response :success
      assert_not_nil assigns(:help_documents)

      get :show, params: { id: help_documents(:one).to_param }
      assert_response :success
      assert_not_nil assigns(:help_document)
    end
  end

  test 'should be available to non logged in users for external help' do
    logout
    with_config_value :internal_help_enabled, false do
      get :index
      assert_response :redirect
      assert_redirected_to Seek::Config.external_help_url
    end
  end

  test 'should get index for internal help' do
    with_config_value :internal_help_enabled, true do
      get :index
      assert_response :success
      assert_not_nil assigns(:help_documents)
    end
  end

  test 'should get index for external help' do
    with_config_value :internal_help_enabled, false do
      get :index
      assert_response :redirect
    end
  end

  test 'should get new for internal help' do
    with_config_value :internal_help_enabled, true do
      get :new
      assert_response :success
    end
  end

  test 'should get new for external help' do
    with_config_value :internal_help_enabled, false do
      get :new
      assert_response :redirect
      assert_redirected_to Seek::Config.external_help_url
    end
  end

  test 'should create help_document for internal help' do
    with_config_value :internal_help_enabled, true do
      assert_difference('HelpDocument.count') do
        post :create, params: { help_document: { identifier: 'test', title: 'new' } }
      end

      assert_redirected_to help_document_path(assigns(:help_document))
      assert_equal 'test', assigns(:help_document).identifier
    end
  end

  test 'should create help_document for external help' do
    with_config_value :internal_help_enabled, false do
      assert_no_difference('HelpDocument.count') do
        post :create, params: { help_document: { identifier: 'test', title: 'new' } }
      end

      assert_redirected_to Seek::Config.external_help_url
    end
  end

  test 'should show help_document for internal help' do
    with_config_value :internal_help_enabled, true do
      get :show, params: { id: help_documents(:one).to_param }
      assert_response :success
    end
  end

  test 'should show help_document for external help' do
    with_config_value :internal_help_enabled, false do
      get :show, params: { id: help_documents(:one).to_param }
      assert_response :redirect
      assert_redirected_to Seek::Config.external_help_url
    end
  end

  test 'should get edit for internal help' do
    with_config_value :internal_help_enabled, true do
      get :edit, params: { id: help_documents(:one).to_param }
      assert_response :success
    end
  end

  test 'should get edit for external help' do
    with_config_value :internal_help_enabled, false do
      get :edit, params: { id: help_documents(:one).to_param }
      assert_response :redirect
      assert_redirected_to Seek::Config.external_help_url
    end
  end

  test 'should update help_document for internal help' do
    with_config_value :internal_help_enabled, true do
      put :update, params: { id: help_documents(:one).to_param, help_document: { title: 'fish' } }
      assert_redirected_to help_document_path(assigns(:help_document))
    end
  end

  test 'should update help_document for external help' do
    with_config_value :internal_help_enabled, false do
      put :update, params: { id: help_documents(:one).to_param, help_document: { title: 'fish' } }
      assert_response :redirect
      assert_redirected_to Seek::Config.external_help_url
    end
  end

  test 'should destroy help_document for internal help' do
    with_config_value :internal_help_enabled, true do
      assert_difference('HelpDocument.count', -1) do
        delete :destroy, params: { id: help_documents(:one).to_param }
      end

      assert_redirected_to help_documents_path
    end
  end

  test 'should destroy help_document for external help' do
    with_config_value :internal_help_enabled, false do
      assert_no_difference('HelpDocument.count') do
        delete :destroy, params: { id: help_documents(:one).to_param }
      end

      assert_redirected_to Seek::Config.external_help_url
    end
  end

  test "shouldn't allow non-admins to create for internal help" do
    with_config_value :internal_help_enabled, true do
      login_as(:aaron)
      get :new
      assert_response :redirect
      assert_not_nil flash[:error]
    end
  end

  test "shouldn't allow non-admins to create for external help" do
    with_config_value :internal_help_enabled, false do
      login_as(FactoryBot.create(:person))
      get :new
      assert_response :redirect
      assert_redirected_to Seek::Config.external_help_url
      assert_nil flash[:error]
    end
  end

  test "shouldn't allow anonymous users to create for internal help" do
    with_config_value :internal_help_enabled, true do
      logout
      get :new
      assert_response :redirect
      assert_not_nil flash[:error]
    end
  end

  # test "shouldn't allow anonymous users to create for external help" do
  #   with_config_value :internal_help_enabled, false do
  #     logout
  #     get :new
  #     assert_response :redirect
  #     assert_redirected_to Seek::Config.external_help_url
  #   end
  # end

  test 'should redirect to index page if available for internal help' do
    with_config_value :internal_help_enabled, true do
      assert_difference('HelpDocument.count') do
        post :create, params: { help_document: { identifier: 'index', title: 'Index page' } }
        get :index
        assert_response :redirect
        assert_nil assigns(:help_documents) # no collection set (not on index page)
        assert_not_nil assigns(:help_document) # doc set (on show page)
      end
    end
  end

  test 'should redirect to index page if available for external help' do
    with_config_value :internal_help_enabled, false do
      assert_no_difference('HelpDocument.count') do
        post :create, params: { help_document: { identifier: 'index', title: 'Index page' } }
        get :index
        assert_response :redirect
        assert_redirected_to Seek::Config.external_help_url
      end
    end
  end

  test "can't change identifier for internal help" do
    with_config_value :internal_help_enabled, true do
      doc = help_documents(:one)

      put :update, params: { id: doc.to_param, help_document: { title: 'hi', identifier: 'fish' } }

      assert_equal 'hi', assigns(:help_document).title
      assert_not_equal 'fish', assigns(:help_document).identifier
    end
  end

  test "shouldn't create docs with invalid identifiers for internal help" do
    with_config_value :internal_help_enabled, true do
      assert_no_difference('HelpDocument.count') do
        post :create, params: { help_document: { identifier: '//#[][]a', title: 'invalid1' } }
        post :create, params: { help_document: { identifier: 'hello/hello', title: 'invalid2' } }
        post :create, params: { help_document: { identifier: '-hello', title: 'invalid3' } }
      end
    end
  end
end
