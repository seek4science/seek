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
    ['min','max'].each do |m|
      json_mm_file = File.join(Rails.root, 'test', 'fixtures', 'files', 'json', 'content_compare', "#{m}_person.json")
      @json_mm["#{m}"] = JSON.parse(File.read(json_mm_file))
    end
  end

  def test_should_create_person
    #debug note: responds with redirect 302 if not really logged in.. could happen if database resets and has no users
    #a_project = Factory(:project)
    ['min','max'].each do |m|
      @json_mm["#{m}"]["data"].delete("id")
      @json_mm["#{m}"]["data"]["attributes"]["email"] = "#{m}_createTest@email.com"
      #@json_mm["#{m}"]["data"]["relationships"]["projects"]["data"].append({:id => a_project.id, :type => "projects"})

      assert_difference('Person.count') do
        assert_difference('NotifieeInfo.count') do
          post "/people.json", @json_mm["#{m}"]
          assert_response :success

          get "/people/#{Person.last.id}.json"
          assert_response :success

          #check some of the content
          h = JSON.parse(response.body)
          assert_equal @json_mm["#{m}"]["data"]["attributes"]["title"], h["data"]["attributes"]["title"]
          check_content(m, h)
        end
      end
    end
  end

  def test_should_update_person
    a_person = Factory(:person)
    ['min','max'].each do |m|
      @json_mm["#{m}"]["data"]["attributes"]["email"] = "#{m}_updateTest@email.com"
      @json_mm["#{m}"]["data"]["attributes"].each do |k,v|
        @json_mm["#{m}"]["data"]["attributes"].delete k if @json_mm["#{m}"]["data"]["attributes"][k].nil?
      end
      @json_mm["#{m}"]["data"]["id"] = "#{a_person.id}"
      put "/people/#{a_person.id}.json", @json_mm["#{m}"]
      assert_response :success

      get "/people/#{a_person.id}.json"
      assert_response :success

      h = JSON.parse(response.body)
      #check no overwrite when no attribute was given
      assert_equal a_person.first_name, h["data"]["attributes"]["first_name"] if (m == 'min')

      check_content(m, h)
    end
  end

  def test_create_should_error_on_given_id
    @json_mm["min"]["data"]["id"] = "100000000"
    @json_mm["min"]["data"]["type"] = "people"
    post "/people.json", @json_mm["min"]
    assert_response :unprocessable_entity
    assert_match "A POST request is not allowed to specify an id", response.body
  end

  def test_create_should_error_on_missing_or_wrong_type
    a_person = Factory(:person)

    #wrong type
    @json_mm["min"]["data"]["type"] = "no type"
    post "/people.json", @json_mm["min"]
    assert_response :unprocessable_entity
    assert_match "The specified data:type does not match the URL's object (no type vs. people)", response.body

    #missing type
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

  def test_update_should_error_on_missing_or_wrong_type
    a_person = Factory(:person)

    #wrong type
    @json_mm["min"]["data"]["type"] = "no type"
    put "/people/#{a_person.id}.json", @json_mm["min"]
    assert_response :unprocessable_entity
    assert_match "The specified data:type does not match the URL's object (no type vs. people)", response.body

    #missing type
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

  def check_content(m, response_hash)
    case m
      when 'min'
        assert_nil response_hash["data"]["attributes"]["expertise"]
        assert_nil response_hash["data"]["attributes"]["tools"]
        assert_nil response_hash["data"]["attributes"]["description"]
      when 'max'
        assert_equal @json_mm["#{m}"]["data"]["attributes"]["expertise"].sort!, response_hash["data"]["attributes"]["expertise"]
        assert_equal @json_mm["#{m}"]["data"]["attributes"]["tools"].sort!, response_hash["data"]["attributes"]["tools"]
        assert_equal @json_mm["#{m}"]["data"]["attributes"]["description"], response_hash["data"]["attributes"]["description"]
    end
  end
end
