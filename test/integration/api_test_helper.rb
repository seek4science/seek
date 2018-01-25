module ApiTestHelper
  include AuthenticatedTestHelper

  def admin_login
    admin = Factory.create(:admin)
    @current_user = admin.user
    @current_user.password = 'blah'
    # log in
    post '/session', login: admin.user.login, password: admin.user.password
  end

  def load_patch_template(hash)
    patch_file = File.join(Rails.root, 'test', 'fixtures', 'files', 'json', 'templates', "patch_#{@clz}.json.erb")
    the_patch = ERB.new(File.read(patch_file))
    namespace = OpenStruct.new(hash)
    to_patch = JSON.parse(the_patch.result(namespace.instance_eval { binding }))
    return to_patch
  end

  # def user_login
  #   User.current_user = Factory(:user, login: 'test')
  #   post '/session', login: 'test', password: 'blah'
  # end

  #only in max object
  # def edit_relationships
  #   @json_mm['max']['data']['relationships'].each do |k,v|
  #     obj = Factory(("#{k}".singularize).to_sym)
  #     @json_mm['max']['data']['relationships'][k]['data'] = [].append({"id": "#{obj.id}", "type": "#{k}"})
  #   end
  # end


  # def check_attr_content(to_post, action)
  #   #check some of the content, h = the response hash after the post/patch action
  #   h = JSON.parse(response.body)
  #   h['data']['attributes'].delete("mbox_sha1sum")
  #   h['data']['attributes'].delete("avatar")
  #   h['data']['attributes'].each do |key, value|
  #     next if (to_post['data']['attributes'][key].nil? && action=="patch")
  #     if value.nil?
  #       assert_nil to_post['data']['attributes'][key]
  #     elsif value.kind_of?(Array)
  #       assert_equal value, to_post['data']['attributes'][key].sort!
  #     else
  #       assert_equal value, to_post['data']['attributes'][key]
  #     end
  #   end
  # end

  # def check_relationships_content(m, action)
  #   @to_post['data']['relationships'].each do |key, value|
  #     assert_equal value, h['data']['relationships'][key]
  #   end
  # end ("#{m}_#{clz}").to_sym

  def test_should_delete_object
    obj = Factory(("#{@clz}").to_sym, contributor: @current_user)
    assert_difference ("#{@clz.classify.constantize}.count"), -1 do
      delete "/#{@plural_clz}/#{obj.id}.json"
      assert_response :success
    end
    get "/#{@plural_clz}/#{obj.id}.json"
    assert_response :not_found
  end

  def test_create_should_error_on_given_id
    post_clone = JSON.parse(JSON.generate(@to_post))
    post_clone['data']['id'] = '100000000'

    assert_no_difference ("#{@clz.classify.constantize}.count") do
      post "/#{@plural_clz}.json", post_clone
      assert_response :unprocessable_entity
      assert_match "A POST request is not allowed to specify an id", response.body
    end
  end

  def test_create_should_error_on_wrong_type
    post_clone = JSON.parse(JSON.generate(@to_post))
    post_clone['data']['type'] = 'wrong'

    assert_no_difference ("#{@clz.classify.constantize}.count") do
      post "/#{@plural_clz}.json", post_clone
      assert_response :unprocessable_entity
      assert_match "The specified data:type does not match the URL's object (#{post_clone['data']['type']} vs. #{@plural_clz})", response.body
    end
  end

  def test_create_should_error_on_missing_type
    post_clone = JSON.parse(JSON.generate(@to_post))
    post_clone['data'].delete('type')

    assert_no_difference ("#{@clz.classify.constantize}.count") do
      post "/#{@plural_clz}.json", post_clone
      assert_response :unprocessable_entity
      assert_match "A POST/PUT request must specify a data:type", response.body
    end
  end

  def test_update_should_error_on_wrong_id
    obj = Factory(("#{@clz}").to_sym)

    to_patch = load_patch_template(id: '100000000')

    assert_no_difference ("#{@clz.classify.constantize}.count") do
      put "/#{@plural_clz}/#{obj.id}.json", to_patch
      assert_response :unprocessable_entity
      assert_match "id specified by the PUT request does not match object-id in the JSON input", response.body
    end
  end

  def test_update_should_error_on_wrong_type
    obj = Factory(("#{@clz}").to_sym)
    to_patch = load_patch_template({})
    to_patch['data']['type'] = 'wrong'

    assert_no_difference ("#{@clz.classify.constantize}.count") do
      put "/#{@plural_clz}/#{obj.id}.json", to_patch
      assert_response :unprocessable_entity
      assert_match "The specified data:type does not match the URL's object (#{to_patch['data']['type']} vs. #{@plural_clz})", response.body
    end
  end

  def test_update_should_error_on_missing_type
    obj = Factory(("#{@clz}").to_sym)
    to_patch = load_patch_template({})
    to_patch['data'].delete('type')

    assert_no_difference ("#{@clz.classify.constantize}.count") do
      put "/#{@plural_clz}/#{obj.id}.json", to_patch
      assert_response :unprocessable_entity
      assert_match "A POST/PUT request must specify a data:type", response.body
    end
  end

end
