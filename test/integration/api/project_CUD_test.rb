require 'test_helper'
require 'integration/api_test_helper'

class ProjectCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = "project"
    @plural_clz = @clz.pluralize

    p = Factory(:project)
    @to_patch = load_template("patch_#{@clz}.json.erb", {id: p.id})

    #min object needed for all tests related to post except 'test_create' which will load min and max subsequently
    @to_post = load_template("post_min_#{@clz}.json.erb", {title: "Post Project" })
  end

  def create_post_values
      @post_values = {title: "Post Project"}
  end

   def test_should_create_project_with_hierarchy
    parent = Factory(:project, title: 'Test Parent')
    @to_post['data']['attributes']['title'] = 'test project hierarchy'
    @to_post['data']['attributes']['parent_id'] = parent.id
    assert_difference('Project.count') do
      post "/projects.json",  @to_post
    end
    assert_includes assigns(:project).ancestors, parent
  end

  def test_normal_user_cannot_create_project
    user_login(Factory(:person))
    assert_no_difference('Project.count') do
      post "/projects.json", @to_post
    end
  end

  # TO DO: revisit after doing relationships linkage
  # def test_should_not_create_project_with_programme_if_not_programme_admin
  #   person = Factory(:person)
  #   user_login(person)
  #   prog = Factory(:programme)
  #   refute_nil prog
  #   @to_post['data']['attributes']['programme_id'] = prog.id
  #   assert_difference('Project.count') do
  #      post "/projects.json",  @to_post
  #      puts response.body
  #
  #      assert_response :success
  #   end
  #
  #   project = assigns(:project)
  #   assert_empty project.programmes
  #   puts project.programmes
  # end
end
