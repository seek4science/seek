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

  test "should hide inaccessible items in treeview" do
    project = Factory(:project)
    inv_one = Factory(:investigation, contributor: @member.person, policy: Factory(:private_policy), projects: [project])

    login_as(Factory(:user))
    inv_two = Factory(:investigation, contributor:User.current_user.person, policy: Factory(:private_policy), projects: [project])

    controller = TreeviewBuilder.new project, nil
    result = controller.send(:build_tree_data)

    json = JSON.parse(result)[0]

    assert_equal "hidden item", json["children"][0]["text"]
    assert_equal inv_two.title, json["children"][1]["text"]
  end
  
end
