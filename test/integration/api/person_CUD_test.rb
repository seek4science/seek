require 'test_helper'

class PersonCUDTest < ActionDispatch::IntegrationTest
  include AuthenticatedTestHelper

  def setup
    #log in
    admin_user = Factory(:admin).user
    admin_user.password = "blah"
    post '/session', login: admin_user.login, password: admin_user.password

    #prepare content for POST
    @json_mm = {}
    ['min', 'max'].each do |m|
      json_mm_file = File.join(Rails.root, 'test', 'fixtures', 'files', 'json', 'content_compare', "#{m}_person.json")
      @json_mm["#{m}"] = JSON.parse(File.read(json_mm_file))
    end
  end

  def test_should_create_person
    #debug note: responds with redirect 302 if not really logged in.. could happen if database resets and has no users
    ['min', 'max'].each do |m|
      @json_mm["#{m}"]["data"].delete("id")
      @json_mm["#{m}"]["data"]["attributes"]["email"] = "#{m}_createTest@email.com"

      assert_difference('Person.count') do
        assert_difference('NotifieeInfo.count') do
          post "/people.json", @json_mm["#{m}"]
          assert_response :success

          get "/people/#{Person.last.id}.json"
          assert_response :success

          check_content(m, "post")
        end
      end
    end
  end

  def test_should_update_person
    a_person = Factory(:person)
    ['min', 'max'].each do |m|
      @json_mm["#{m}"]["data"]["attributes"]["email"] = "#{m}_updateTest@email.com"
      @json_mm["#{m}"]["data"]["attributes"].each do |k, v|
        @json_mm["#{m}"]["data"]["attributes"].delete k if @json_mm["#{m}"]["data"]["attributes"][k].nil?
      end
      @json_mm["#{m}"]["data"]["id"] = "#{a_person.id}"
      patch "/people/#{a_person.id}.json", @json_mm["#{m}"]
      assert_response :success

      get "/people/#{a_person.id}.json"
      assert_response :success
      @json_mm["min"]["data"]["attributes"]["title"] =
          a_person.first_name + " " + @json_mm["min"]["data"]["attributes"]["last_name"]
      check_content(m, "patch")
    end
  end

  def test_create_should_error_on_given_id
    @json_mm["min"]["data"]["id"] = "100000000"
    @json_mm["min"]["data"]["type"] = "people"
    post "/people.json", @json_mm["min"]
    assert_response :unprocessable_entity
    assert_match "A POST request is not allowed to specify an id", response.body
  end

  def test_create_should_error_on_wrong_type
    a_person = Factory(:person)
    @json_mm["min"]["data"]["type"] = "wrong"
    post "/people.json", @json_mm["min"]
    assert_response :unprocessable_entity
    assert_match "The specified data:type does not match the URL's object (#{@json_mm["min"]["data"]["type"]} vs. people)", response.body
  end

  def test_create_should_error_on_missing_type
    a_person = Factory(:person)
    @json_mm["min"]["data"].delete("type")
    post "/people.json", @json_mm["min"]
    assert_response :unprocessable_entity
    assert_match "A POST/PUT request must specify a data:type", response.body
  end

  def test_update_should_error_on_wrong_id
    a_person = Factory(:person)
    @json_mm["min"]["data"]["id"] = "100000000"
    @json_mm["min"]["data"]["type"] = "people"

    put "/people/#{a_person.id}.json", @json_mm["min"]
    assert_response :unprocessable_entity
    assert_match "id specified by the PUT request does not match object-id in the JSON input", response.body

    @json_mm["min"]["data"]["id"] = a_person.id
    @json_mm["min"]["data"]["attributes"]["email"] = "updateTest@email.com"
    put "/people/#{a_person.id}.json", @json_mm["min"]
    assert_response :success
  end

  def test_update_should_error_wrong_type
    a_person = Factory(:person)
    @json_mm["min"]["data"]["type"] = "wrong"
    put "/people/#{a_person.id}.json", @json_mm["min"]
    assert_response :unprocessable_entity
    assert_match "The specified data:type does not match the URL's object (#{@json_mm["min"]["data"]["type"]} vs. people)", response.body
  end

  def test_update_should_error_on_missing_type
    a_person = Factory(:person)
    @json_mm["min"]["data"].delete("type")
    put "/people/#{a_person.id}.json", @json_mm["min"]
    assert_response :unprocessable_entity
    assert_match "A POST/PUT request must specify a data:type", response.body
  end

  def test_should_delete_person
    a_person = Factory(:person)
    get "/people/#{a_person.id}.json"
    delete "/people/#{a_person.id}.json"
    assert_response :success

    get "/people/#{a_person.id}.json"
    assert_response :not_found
  end

  private

  def check_content(m, action)
    #check some of the content
    h = JSON.parse(response.body)
    h['data']['attributes'].delete("mbox_sha1sum")
    h['data']['attributes'].delete("avatar")
    h['data']['attributes'].each do |key, value|
      next if (@json_mm["#{m}"]['data']['attributes'][key].nil? && action="patch")
      if value.nil?
        assert_nil @json_mm["#{m}"]['data']['attributes'][key]
      elsif value.kind_of?(Array)
        assert_equal value, @json_mm["#{m}"]['data']['attributes'][key].sort!
      else
        assert_equal value, @json_mm["#{m}"]['data']['attributes'][key]
      end
    end
  end
end
