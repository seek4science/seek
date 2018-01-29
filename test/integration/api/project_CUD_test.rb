require 'test_helper'
require 'integration/api_integration_test_helper'

class ProjectCUDTest < ActionDispatch::IntegrationTest
  include ApiIntegrationTestHelper

  def setup
    admin_login
    @clz = "project"
    @plural_clz = @clz.pluralize

    load_mm_objects("project")
    edit_relationships
  end

  def test_should_create_project
    #min would create a project with a blank programme, max: with a programme.
    ['min', 'max'].each do |m|
      assert_difference('Project.count') do
        post "/projects.json", @json_mm["#{m}"]
        assert_response :success

        get "/projects/#{Project.last.id}.json"
        assert_response :success

        check_attr_content(@json_mm["#{m}"], "post")
      end
    end
  end

  def test_should_create_project_with_hierarchy
    parent = Factory(:project, title: 'Test Parent')
    @json_mm['min']['data']['attributes']['title'] = 'test project hierarchy'
    @json_mm['min']['data']['attributes']['parent_id'] = parent.id
    assert_difference('Project.count') do
      post "/projects.json",  @json_mm['min']
    end

    assert_includes assigns(:project).ancestors, parent
  end


  # def test_should_not_create_project_with_programme_if_not_programme_admin
  #   person = Factory(:programme_administrator)
  #   login_as(person)
  #   user_login
  #   prog = Factory(:programme)
  #   refute_nil prog
  #
  #   assert_difference('Project.count') do
  #     post :create, project: { title: 'proj with prog', programme_id: prog.id }
  #   end
  #
  #   project = assigns(:project)
  #   assert_empty project.programmes
  # end
  #
  def test_should_update_project
    project = Factory(:project)
    remove_nil_values_before_update
    ['min', 'max'].each do |m|
      @json_mm["#{m}"]["data"]["id"] = "#{project.id}"
      patch "/projects/#{project.id}.json", @json_mm["#{m}"]
      assert_response :success

      get "/projects/#{project.id}.json"
      assert_response :success
      check_attr_content(@json_mm["#{m}"], "patch")
    end
  end

  def test_normal_user_cannot_create_project
    user_login(Factory(:person))
    assert_no_difference('Project.count') do
      post "/projects.json", @json_mm["min"]
    end
  end

  def test_normal_user_cannot_update_project
    remove_nil_values_before_update
    user_login(Factory(:person))
    project = Factory(:project)
    @json_mm["min"]["data"]["id"] = "#{project.id}"
    @json_mm["min"]["data"]["attributes"]["title"] = "updated project"
    patch "/projects/#{project.id}.json", @json_mm["min"]
    assert_response :forbidden
  end

  def test_normal_user_cannot_delete_project
    user_login(Factory(:person))
    project = Factory(:project)
    assert_no_difference('Project.count') do
      delete "/projects/#{project.id}.json"
      assert_response :forbidden
    end
  end
end
