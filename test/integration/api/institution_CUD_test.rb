require 'test_helper'
require 'integration/api_integration_test_helper'

class InstitutionCUDTest < ActionDispatch::IntegrationTest
  include ApiIntegrationTestHelper

  def setup
    admin_login
    @clz = "institution"
    @plural_clz = @clz.pluralize

    load_mm_objects("institution")
  end

  def test_should_create_institution
    #debug note: responds with redirect 302 if not really logged in.. could happen if database resets and has no users
    ['min', 'max'].each do |m|
      assert_difference('Institution.count') do
          post "/institutions.json", @json_mm["#{m}"]
          assert_response :success

          get "/institutions/#{Institution.last.id}.json"
          assert_response :success

          check_attr_content(@json_mm["#{m}"], "post")
      end
    end
  end

  def test_should_update_institution
    inst = Factory(:institution)
    remove_nil_values_before_update
    ['min', 'max'].each do |m|
      @json_mm["#{m}"]["data"]["id"] = "#{inst.id}"
      patch "/institutions/#{inst.id}.json", @json_mm["#{m}"]
      assert_response :success

      get "/institutions/#{inst.id}.json"
      assert_response :success
      check_attr_content(@json_mm["#{m}"], "patch")
    end
  end

  def test_normal_user_cannot_create_institution
    user_login(Factory(:person))
    assert_no_difference('Institution.count') do
      post "/institutions.json", @json_mm["min"]
    end
  end

  def test_normal_user_cannot_update_institution
    remove_nil_values_before_update
    user_login(Factory(:person))
    inst = Factory(:institution)
    @json_mm["min"]["data"]["id"] = "#{inst.id}"
    @json_mm["min"]["data"]["attributes"]["title"] = "updated institution"
    patch "/institutions/#{inst.id}.json", @json_mm["min"]
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
