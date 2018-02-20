require 'test_helper'
require 'integration/api_test_helper'

class InstitutionCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = "institution"
    @plural_clz = @clz.pluralize
    inst = Factory(:institution)

    post_file = File.join(ApiTestHelper.template_dir, "post_min_#{@clz}.json.erb")
    template = ERB.new(File.read(post_file))
    namespace = OpenStruct.new(title: "Post "+inst.title, country: inst.country)
    @to_post = JSON.parse(template.result(namespace.instance_eval { binding }))

    patch_file = File.join(ApiTestHelper.template_dir, "patch_#{@clz}.json.erb")
    the_patch = ERB.new(File.read(patch_file))
    namespace = OpenStruct.new(id: inst.id)
    @to_patch = JSON.parse(the_patch.result(namespace.instance_eval { binding } ) )

  end

  # def test_should_create_institution
  #   #debug note: responds with redirect 302 if not really logged in.. could happen if database resets and has no users
  #   ['min', 'max'].each do |m|
  #     assert_difference('Institution.count') do
  #         post "/institutions.json", @json_mm["#{m}"]
  #         assert_response :success
  #
  #         get "/institutions/#{Institution.last.id}.json"
  #         assert_response :success
  #
  #         check_attr_content(@json_mm["#{m}"], "post")
  #     end
  #   end
  # end
  #
  # def test_should_update_institution
  #   inst = Factory(:institution)
  #   remove_nil_values_before_update
  #   ['min', 'max'].each do |m|
  #     @json_mm["#{m}"]["data"]["id"] = "#{inst.id}"
  #     patch "/institutions/#{inst.id}.json", @json_mm["#{m}"]
  #     assert_response :success
  #
  #     get "/institutions/#{inst.id}.json"
  #     assert_response :success
  #     check_attr_content(@json_mm["#{m}"], "patch")
  #   end
  # end

  def test_normal_user_cannot_create_institution
    user_login(Factory(:person))
    assert_no_difference('Institution.count') do
      post "/institutions.json", @to_post
    end
  end

  def test_normal_user_cannot_update_institution
    user_login(Factory(:person))
    @to_patch["data"]["attributes"]["title"] = "update institution fails for a normal user"
    patch "/institutions/#{@to_patch["data"]["id"]}.json", @to_patch
    assert_response :forbidden
  end

  def test_normal_user_cannot_delete_institution
    user_login(Factory(:person))
    inst = Factory(:institution)
    assert_no_difference('Institution.count') do
      delete "/institutions/#{inst.id}.json"
      assert_response :forbidden
    end
  end

end
