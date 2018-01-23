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
    #debug note: responds with redirect 302 if not really logged in.. could happen if database resets and has no users
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

end
