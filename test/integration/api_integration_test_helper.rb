module ApiIntegrationTestHelper
  include AuthenticatedTestHelper

  def admin_login
    admin_user = Factory(:admin).user
    admin_user.password = "blah"
    post '/session', login: admin_user.login, password: admin_user.password
  end

  def user_login
    User.current_user = Factory(:user, login: 'test')
    post '/session', login: 'test', password: 'blah'
  end

  def load_mm_objects(clz)
    @json_mm = {}
    ['min', 'max'].each do |m|
      json_mm_file = File.join(Rails.root, 'test', 'fixtures', 'files', 'json', 'content_compare', "#{m}_#{clz}.json")
      @json_mm["#{m}"] = JSON.parse(File.read(json_mm_file))
      #TO DO may need to separate that later
      @json_mm["#{m}"]["data"].delete("id")
    end
  end

  def remove_nil_values_before_update
    ['min', 'max'].each do |m|
      @json_mm["#{m}"]["data"]["attributes"].each do |k, v|
        @json_mm["#{m}"]["data"]["attributes"].delete k if @json_mm["#{m}"]["data"]["attributes"][k].nil?
      end
    end
  end

  def check_attr_content(to_post, action)
    #check some of the content, h = the response hash after the post/patch action
    h = JSON.parse(response.body)
    h['data']['attributes'].delete("mbox_sha1sum")
    h['data']['attributes'].delete("avatar")
    h['data']['attributes'].each do |key, value|
      next if (to_post['data']['attributes'][key].nil? && action=="patch")
      if value.nil?
        assert_nil to_post['data']['attributes'][key]
      elsif value.kind_of?(Array)
        assert_equal value, to_post['data']['attributes'][key].sort!
      else
        assert_equal value, to_post['data']['attributes'][key]
      end
    end
  end

  # def check_relationships_content(m, action)
  #   @to_post['data']['relationships'].each do |key, value|
  #     assert_equal value, h['data']['relationships'][key]
  #   end
  # end ("#{m}_#{clz}").to_sym

  def test_should_delete_object
    obj = Factory(("#{@clz}").to_sym)
    #get "/people/#{a_person.id}.json"
    delete "/#{@plural_clz}/#{obj.id}.json"
    assert_response :success

    get "/#{@plural_clz}/#{obj.id}.json"
    assert_response :not_found
  end

  def test_create_should_error_on_given_id
    @json_mm["min"]["data"]["id"] = "100000000"
    @json_mm["min"]["data"]["type"] = "#{@plural_clz}"
    post "/#{@plural_clz}.json", @json_mm["min"]
    assert_response :unprocessable_entity
    assert_match "A POST request is not allowed to specify an id", response.body
  end

  def test_create_should_error_on_wrong_type
    @json_mm["min"]["data"]["type"] = "wrong"
    post "/#{@plural_clz}.json", @json_mm["min"]
    assert_response :unprocessable_entity
    assert_match "The specified data:type does not match the URL's object (#{@json_mm["min"]["data"]["type"]} vs. #{@plural_clz})", response.body
  end


  def test_create_should_error_on_missing_type
    @json_mm["min"]["data"].delete("type")
    post "/#{@plural_clz}.json", @json_mm["min"]
    assert_response :unprocessable_entity
    assert_match "A POST/PUT request must specify a data:type", response.body
  end

  def test_update_should_error_on_wrong_id
    obj = Factory(("#{@clz}").to_sym)
    @json_mm["min"]["data"]["id"] = "100000000"
    @json_mm["min"]["data"]["type"] = "#{@plural_clz}"

    #wrong id = failire
    put "/#{@plural_clz}/#{obj.id}.json", @json_mm["min"]
    assert_response :unprocessable_entity
    assert_match "id specified by the PUT request does not match object-id in the JSON input", response.body

    #correct id = success
    @json_mm["min"]["data"]["id"] = obj.id
    @json_mm["min"]["data"]["attributes"]["title"] = "Updated #{@clz}"
    put "/#{@plural_clz}/#{obj.id}.json", @json_mm["min"]
    assert_response :success
  end

  def test_update_should_error_wrong_type
    obj = Factory(("#{@clz}").to_sym)
    @json_mm["min"]["data"]["type"] = "wrong"
    put "/#{@plural_clz}/#{obj.id}.json", @json_mm["min"]
    assert_response :unprocessable_entity
    assert_match "The specified data:type does not match the URL's object (#{@json_mm["min"]["data"]["type"]} vs. #{@plural_clz})", response.body
  end

  def test_update_should_error_on_missing_type
    obj = Factory(("#{@clz}").to_sym)
    @json_mm["min"]["data"].delete("type")
    put "/#{@plural_clz}/#{obj.id}.json", @json_mm["min"]
    assert_response :unprocessable_entity
    assert_match "A POST/PUT request must specify a data:type", response.body
  end

end
