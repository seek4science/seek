require "test_helper"
class SinglePagesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    @member = Factory :user
    login_as @member
  end

  test 'should show' do
    with_config_value(:project_single_page_enabled, true) do
      project = Factory(:project)
      get :show, params: { id: project.id }
      assert_response :success
    end
  end

  test 'should redirect if not enabled' do
    with_config_value(:project_single_page_enabled, false) do
      project = Factory(:project)
      get :show,  params: { id: project.id }
      assert_redirected_to project_path(project)
    end
  end
  
end
