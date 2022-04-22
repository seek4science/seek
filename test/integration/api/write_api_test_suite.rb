module WriteApiTestSuite
  DEBUG = false # || true
  extend ActiveSupport::Testing::Declarative # Allows `test 'bla' do` definitions
  include ApiTestHelper

  def model
    raise NotImplementedError
  end

  def resource
    if model.method_defined?(:contributor=)
      Factory(singular_name.to_sym, contributor: current_person)
    else
      Factory(singular_name.to_sym)
    end
  end

  def post_json
    template = "post_max_#{singular_name}.json.erb"
    load_template(template, post_values)
  end

  def post_values
    {}
  end

  def patch_values
    {}
  end

  def ignore_non_read_or_write_attributes
    ['updated_at', 'creators']
  end

  ['min','max'].each do |m|
    test "can create #{m} resource" do
      expected = to_post = load_template("post_#{m}_#{singular_name}.json.erb", post_values)

      validate_json_against_fragment to_post.to_json, "#/definitions/#{singular_name.camelize(:lower)}Post"

      # debug note: responds with redirect 302 if not really logged in.. could happen if database resets and has no users
      assert_difference("#{singular_name.classify}.count") do
        post collection_url, params: to_post.to_json, headers: { 'CONTENT_TYPE' => 'application/vnd.api+json' }
        assert_response :success
      end

      validate_json_against_fragment response.body, "#/definitions/#{singular_name.camelize(:lower)}Response"

      actual = JSON.parse(response.body)

      expected['data']['attributes'] ||= {}
      expected['data']['attributes'].except!(*ignore_non_read_or_write_attributes)
      expected['data']['attributes'].merge!(populate_extra_attributes(to_post))
      expected['data']['relationships'] ||= {}
      expected['data']['relationships'].merge!(populate_extra_relationships(to_post))

      if DEBUG
        puts "Expected:\n #{expected.inspect}\n"
        puts "Actual:\n #{actual.inspect}"
      end

      hash_comparison(expected['data']['attributes'], actual['data']['attributes'])
      hash_comparison(expected['data']['relationships'], actual['data']['relationships'])
    end
  end

  test 'can delete resource' do
    obj = resource

    # FIXME: programme factory cannot automatically be deleted, as it has projects associated
    if (obj.is_a?(Programme))
      obj.projects = []
      obj.save!
    end

    assert_difference ("#{singular_name.classify.constantize}.count"), -1 do
      delete member_url(obj)
      assert_response :success
    end
    get member_url(obj)
    assert_response :not_found
    validate_json_against_fragment response.body, '#/definitions/errors'
  end

  test 'unauthorized user cannot update resource' do
    obj = object_with_private_policy
    user_login(Factory(:person))
    post_json["data"]["id"] = "#{obj.id}"
    post_json["data"]["attributes"]["title"] = "updated by an unauthorized"
    patch member_url(obj), params: post_json
    assert_response :forbidden
    validate_json_against_fragment response.body, '#/definitions/errors'
  end

  test 'unauthorized user cannot delete resource' do
    obj = object_with_private_policy
    user_login(Factory(:person))
    assert_no_difference("#{singular_name.classify.constantize}.count") do
      delete member_url(obj)
      assert_response :forbidden
      validate_json_against_fragment response.body, '#/definitions/errors'
    end
  end

  test 'creating resource with an ID should throw error' do
    post_clone = JSON.parse(JSON.generate(post_json))
    post_clone['data']['id'] = '100000000'

    assert_no_difference("#{singular_name.classify.constantize}.count") do
      post collection_url, params: post_clone
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match 'A POST request is not allowed to specify an id', response.body
    end
  end

  test 'creating resource with the wrong type should throw error' do
    post_clone = JSON.parse(JSON.generate(post_json))
    post_clone['data']['type'] = 'wrong'

    assert_no_difference("#{singular_name.classify.constantize}.count") do
      post collection_url, params: post_clone
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match "The specified data:type does not match the URL's object (#{post_clone['data']['type']} vs. #{plural_name})", response.body
    end
  end

  test 'creating resource with a missing type should throw error' do
    post_clone = JSON.parse(JSON.generate(post_json))
    post_clone['data'].delete('type')

    assert_no_difference("#{singular_name.classify.constantize}.count") do
      post collection_url, params: post_clone
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match "A POST/PUT request must specify a data:type", response.body
    end
  end

  ['min', 'max'].each do |m|
    test "can update #{m} resource" do
      to_patch = load_template("patch_#{m}_#{singular_name}.json.erb", patch_values)

      #fetch original object
      obj_id = to_patch['data']['id']
      obj = singular_name.classify.constantize.find(obj_id)

      get member_url(obj)
      assert_response :success
      expected = JSON.parse(response.body)

      validate_json_against_fragment to_patch.to_json, "#/definitions/#{singular_name.camelize(:lower)}Patch"

      assert_no_difference("#{singular_name.classify}.count") do
        j = to_patch.to_json
        patch member_url(obj), params: j, headers: { 'CONTENT_TYPE' => 'application/vnd.api+json' }
        assert_response :success
      end

      validate_json_against_fragment response.body, "#/definitions/#{singular_name.camelize(:lower)}Response"

      actual = JSON.parse(response.body)

      expected['data']['attributes'].merge!(to_patch['data']['attributes'] || {})
      expected['data']['attributes'].except!(*ignore_non_read_or_write_attributes)
      expected['data']['attributes'].merge!(populate_extra_attributes(to_patch))
      expected['data']['relationships'].merge!(to_patch['data']['relationships'] || {})
      expected['data']['relationships'].merge!(populate_extra_relationships(to_patch))

      if DEBUG
        puts "Expected:\n #{expected.inspect}\n"
        puts "Actual:\n #{actual.inspect}"
      end

      hash_comparison(expected['data']['attributes'], actual['data']['attributes'])
      hash_comparison(expected['data']['relationships'], actual['data']['relationships'])
    end
  end

  test 'updating resource with the wrong ID should throw error' do
    obj = resource

    to_patch = load_patch_template(id: '100000000')

    assert_no_difference ("#{singular_name.classify.constantize}.count") do
      put member_url(obj), params: to_patch
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match "id specified by the PUT request does not match object-id in the JSON input", response.body
    end
  end

  test 'updating resource with the wrong type should throw error' do
    obj = resource
    to_patch = load_patch_template
    to_patch['data']['type'] = 'wrong'

    assert_no_difference ("#{singular_name.classify.constantize}.count") do
      put member_url(obj), params: to_patch
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match "The specified data:type does not match the URL's object (#{to_patch['data']['type']} vs. #{plural_name})", response.body
    end
  end

  test 'updating resource with a missing type should throw error' do
    obj = resource
    to_patch = load_patch_template
    to_patch['data'].delete('type')

    assert_no_difference ("#{singular_name.classify.constantize}.count") do
      put member_url(obj), params: to_patch
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match "A POST/PUT request must specify a data:type", response.body
    end
  end
end
