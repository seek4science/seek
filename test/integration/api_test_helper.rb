module ApiTestHelper
  include AuthenticatedTestHelper

  def admin_login
    admin = Factory.create(:admin)
    @current_person = admin
    @current_user = admin.user
    # log in
    post '/session', login: admin.user.login, password: ('0' * User::MIN_PASSWORD_LENGTH)
  end

  def self.template_dir
    File.join(Rails.root, 'test', 'fixtures',
              'files', 'json', 'templates')
  end

  def self.render_erb (path, locals)
    content = File.read(File.join(ApiTestHelper.template_dir, path))
    template = ERB.new(content)
    h = locals
    h[:r] = method(:render_erb)
    namespace = OpenStruct.new(h)
    template.result(namespace.instance_eval {binding})
  end

  def load_patch_template(hash)
    patch_file = File.join(Rails.root, 'test', 'fixtures',
                                     'files', 'json', 'templates', "patch_#{@clz}.json.erb")
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

  def test_create
    if @to_post.blank?
      skip
    end

    # debug note: responds with redirect 302 if not really logged in.. could happen if database resets and has no users
    assert_difference("#{@clz.classify}.count") do
      post "/#{@plural_clz}.json", @to_post

      assert_response :success
    end

    # check some of the content
    h = JSON.parse(response.body)

    hash_comparison(@to_post['data']['attributes'], h['data']['attributes'])
    hash_comparison(populate_extra_attributes, h['data']['attributes'])

    hash_comparison(@to_post['data']['relationships'], h['data']['relationships'])
    hash_comparison(populate_extra_relationships, h['data']['relationships'])
  end

  def test_should_delete_object
    obj = Factory(("#{@clz}").to_sym, contributor: @current_person)
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

  def test_update
    if @to_post.blank? then
      skip
    end
    post "/#{@plural_clz}.json", @to_post
    assert_response :success

    h = JSON.parse(response.body)
    the_id = h['data']['id']

    patch_file = File.join(Rails.root, 'test', 'fixtures', 'files', 'json', 'templates', "patch_#{@clz}.json.erb")
    the_patch = ERB.new(File.read(patch_file))
    namespace = OpenStruct.new(id: the_id)
    @to_patch = JSON.parse(the_patch.result(namespace.instance_eval { binding } ) )

    assert_no_difference( "#{@clz.classify}.count") do
      patch "/#{@plural_clz}/#{the_id}.json", @to_patch
      assert_response :success
    end

    h = JSON.parse(response.body)

    # Check the changed attributes and relationships
    if @to_patch['data'].key?('attributes')
      hash_comparison(@to_patch['data']['attributes'], h['data']['attributes'])
    end

    if @to_patch['data'].key?('relationships')
      hash_comparison(@to_patch['data']['relationships'], h['data']['relationships'])
    end

    # Check the original, unchanged attributes and relationships
    if @to_post['data'].key?('attributes') && @to_patch['data'].key?('attributes')
      original_attributes = @to_post['data']['attributes'].except(@to_patch['data']['attributes'].keys)
      hash_comparison(original_attributes, h['data']['attributes'])
    end

    if @to_post['data'].key?('relationships') && @to_patch['data'].key?('relationships')
      original_relationships = @to_post['data']['relationships'].except(@to_patch['data']['relationships'].keys)
      hash_comparison(original_relationships, h['data']['relationships'])
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

  private

  ##
  # Compare `result` Hash against `source`.
  def hash_comparison(source, result)
    source.each do |key, value|
      deep_comparison(value, result[key], key)
    end
  end

  ##
  # Compares `result` against `source`. If `source` is a Hash, compare each each key/value pair with that in `result`. If `source` is an Array, compare each value.
  # `key` is used to generate meaningful failure messages if the assertion fails.
  def deep_comparison(source, result, key)
    if source.is_a?(Hash)
      source.each do |sub_key, sub_value|
        actual = result.try(:[], sub_key)
        assert_equal sub_value, actual, "Expected #{key}[#{sub_key}] to be `#{sub_value}` but was `#{actual}`"
      end
    elsif source.is_a?(Array)
      sorted = result.sort
      source.sort.each_with_index do |sub_value, index|
        deep_comparison(sub_value, sorted[index], "#{key[index]}")
      end
    else
      assert_equal source, result, "Expected #{key} to be `#{source}` but was `#{result}`"
    end
  end
end
