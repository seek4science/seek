require 'test_helper'
require 'integration/api_integration_test_helper'

class PersonCUDTest < ActionDispatch::IntegrationTest
  include ApiIntegrationTestHelper

  def setup
    admin_login
    @clz = "person"
    @plural_clz = @clz.pluralize

    load_mm_objects(@clz)
  end

  def test_should_create_person
    #debug note: responds with redirect 302 if not really logged in.. could happen if database resets and has no users
    ['min', 'max'].each do |m|
      @json_mm["#{m}"]["data"]["attributes"]["email"] = "#{m}_createTest@email.com"

      assert_difference('Person.count') do
        assert_difference('NotifieeInfo.count') do
          post "/people.json", @json_mm["#{m}"]
          assert_response :success

          get "/people/#{Person.last.id}.json"
          assert_response :success

          check_attr_content(@json_mm["#{m}"], "post")
        end
      end
    end
  end

  def test_should_update_person
    a_person = Factory(:person)
    user_login(a_person)
    remove_nil_values_before_update

    ['min', 'max'].each do |m|
      @json_mm["#{m}"]["data"]["attributes"]["email"] = "#{m}_updateTest@email.com"

      @json_mm["#{m}"]["data"]["id"] = "#{a_person.id}"
      patch "/people/#{a_person.id}.json", @json_mm["#{m}"]
      assert_response :success

      get "/people/#{a_person.id}.json"
      assert_response :success
      @json_mm["min"]["data"]["attributes"]["title"] =
          a_person.first_name + " " + @json_mm["min"]["data"]["attributes"]["last_name"]
      check_attr_content(@json_mm["#{m}"], "patch")
    end
  end

  def test_normal_user_cannot_create_person
    user_login(Factory(:person))
    @json_mm["min"]["data"]["attributes"]["email"] = "normalUserCreate@testEmail.com"
    assert_no_difference('Person.count') do
      post "/people.json", @json_mm["min"]
    end
  end

  def test_normal_user_cannot_update_others
    remove_nil_values_before_update
    user_login(Factory(:person))
    other_person = Factory(:person)
    @json_mm["min"]["data"]["id"] = "#{other_person.id}"
    @json_mm["min"]["data"]["attributes"]["email"] = "updateTest@email.com"
    patch "/people/#{other_person.id}.json", @json_mm["min"]
    assert_response :forbidden
  end

  def test_admin_can_update_others
    remove_nil_values_before_update
    other_person = Factory(:person)
    ['min', 'max'].each do |m|
       @json_mm["#{m}"]["data"]["id"] = "#{other_person.id}"
       @json_mm["#{m}"]["data"]["attributes"]["email"] = "updateTest@email.com"
       patch "/people/#{other_person.id}.json", @json_mm["#{m}"]
       assert_response :success
    end

  end

end
