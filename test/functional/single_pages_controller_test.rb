require 'test_helper'
class SinglePagesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    @member = FactoryBot.create :user
    login_as @member
  end

  test 'should show' do
    with_config_value(:project_single_page_enabled, true) do
      project = FactoryBot.create(:project)
      get :show, params: { id: project.id }
      assert_response :success
    end
  end

  test 'should hide inaccessible items in treeview' do
    project = FactoryBot.create(:project)
    FactoryBot.create(:investigation, contributor: @member.person, policy: FactoryBot.create(:private_policy),
                            projects: [project])

    login_as(FactoryBot.create(:user))
    inv_two = FactoryBot.create(:investigation, contributor: User.current_user.person, policy: FactoryBot.create(:private_policy),
                                      projects: [project])

    controller = TreeviewBuilder.new project, nil
    result = controller.send(:build_tree_data)

    json = JSON.parse(result)[0]

    assert_equal 'hidden item', json['children'][0]['text']
    assert_equal inv_two.title, json['children'][1]['text']
  end

  test 'should not export isa from unauthorized investigation' do
    with_config_value(:project_single_page_enabled, true) do
      project = FactoryBot.create(:project)
      investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy), projects: [project])
      get :export_isa, params: { id: project.id, investigation_id: investigation.id }
      assert_equal flash[:error], "The investigation cannot be found!"
      assert_redirected_to action: :show
    end
  end
end
