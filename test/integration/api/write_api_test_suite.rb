module WriteApiTestSuite
  extend ActiveSupport::Testing::Declarative # Allows `test 'bla' do` definitions
  include ApiTestHelper

  def model
    raise NotImplementedError
  end

  def resource
    Factory(singular_name.to_sym, contributor: @current_person)
  end

  def post_values
    nil
  end

  def patch_values
    nil
  end

  ['min','max'].each do |m|
    test "can create #{m} resource" do
      debug = false # || true # Uncomment to enable

      if post_values
        to_post = load_template("post_#{m}_#{singular_name}.json.erb", post_values)
      else
        template_file = File.join(ApiTestHelper.template_dir, "post_#{m}_#{singular_name}.json.erb")
        template = ERB.new(File.read(template_file))
        to_post = JSON.parse(template.result(binding))
      end
      puts "create, to_post #{m}", to_post if debug

      if to_post.blank?
        skip
      end

      validate_json_against_fragment to_post.to_json, "#/definitions/#{singular_name.camelize(:lower)}Post"

      # debug note: responds with redirect 302 if not really logged in.. could happen if database resets and has no users
      assert_difference("#{singular_name.classify}.count") do
        post collection_url, params: to_post.to_json, headers: { 'CONTENT_TYPE' => 'application/vnd.api+json' }
        if debug
          puts "==== Response ===="
          puts response.body
          puts "=================="
        end
        assert_response :success
      end

      validate_json_against_fragment response.body, "#/definitions/#{singular_name.camelize(:lower)}Response"

      # content check
      h = JSON.parse(response.body)
      to_ignore = (defined? ignore_non_read_or_write_attributes) ? ignore_non_read_or_write_attributes : []

      hash_comparison(to_post['data']['attributes'].except(*to_ignore), h['data']['attributes'])

      if to_post['data'].has_key?('relationships')
        hash_comparison(to_post['data']['relationships'], h['data']['relationships'])
      end

      hash_comparison(populate_extra_attributes(to_post), h['data']['attributes'])
      hash_comparison(populate_extra_relationships(to_post), h['data']['relationships'])
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
    @to_post["data"]["id"] = "#{obj.id}"
    @to_post["data"]["attributes"]["title"] = "updated by an unauthorized"
    patch member_url(obj), params: @to_post
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
    post_clone = JSON.parse(JSON.generate(@to_post))
    post_clone['data']['id'] = '100000000'

    assert_no_difference("#{singular_name.classify.constantize}.count") do
      post collection_url, params: post_clone
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match 'A POST request is not allowed to specify an id', response.body
    end
  end

  test 'creating resource with the wrong type should throw error' do
    post_clone = JSON.parse(JSON.generate(@to_post))
    post_clone['data']['type'] = 'wrong'

    assert_no_difference("#{singular_name.classify.constantize}.count") do
      post collection_url, params: post_clone
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match "The specified data:type does not match the URL's object (#{post_clone['data']['type']} vs. #{plural_name})", response.body
    end
  end

  test 'creating resource with a missing type should throw error' do
    post_clone = JSON.parse(JSON.generate(@to_post))
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
      if patch_values
        @to_patch = load_template("patch_#{m}_#{singular_name}.json.erb", patch_values)
      end

      if @to_patch.blank?
        skip
      end

      #fetch original object
      obj_id = @to_patch['data']['id']
      obj = singular_name.classify.constantize.find(obj_id)
      get member_url(obj)
      assert_response :success
      #puts "after get: ", response.body
      original = JSON.parse(response.body)

      validate_json_against_fragment @to_patch.to_json, "#/definitions/#{singular_name.camelize(:lower)}Patch"

      assert_no_difference("#{singular_name.classify}.count") do
        j = @to_patch.to_json
        patch member_url(obj), params: j, headers: { 'CONTENT_TYPE' => 'application/vnd.api+json' }
        assert_response :success
      end

      validate_json_against_fragment response.body, "#/definitions/#{singular_name.camelize(:lower)}Response"

      h = JSON.parse(response.body)

      #check the post-processed attributes and relationships
      hash_comparison(populate_extra_attributes(@to_patch), h['data']['attributes'])
      hash_comparison(populate_extra_relationships(@to_patch), h['data']['relationships'])

      to_ignore = (defined? ignore_non_read_or_write_attributes) ? ignore_non_read_or_write_attributes : []
      to_ignore << 'updated_at'
      to_ignore << 'creators'

      # Check the changed attributes and relationships
      if @to_patch['data'].key?('attributes')
        hash_comparison(@to_patch['data']['attributes'].except(*to_ignore), h['data']['attributes'])
      end

      if @to_patch['data'].key?('relationships')
        hash_comparison(@to_patch['data']['relationships'], h['data']['relationships'])
      end

      # Check the original, unchanged attributes and relationships
      if original['data'].key?('attributes') && @to_patch['data'].key?('attributes')
        original_attributes = original['data']['attributes'].except(*(to_ignore + @to_patch['data']['attributes'].keys))
        hash_comparison(original_attributes, h['data']['attributes'])
      end

      if original['data'].key?('relationships') && @to_patch['data'].key?('relationships')
        original_relationships = original['data']['relationships'].except(*@to_patch['data']['relationships'].keys)
        hash_comparison(original_relationships, h['data']['relationships'])
      end
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
    to_patch = load_patch_template({})
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
    to_patch = load_patch_template({})
    to_patch['data'].delete('type')

    assert_no_difference ("#{singular_name.classify.constantize}.count") do
      put member_url(obj), params: to_patch
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match "A POST/PUT request must specify a data:type", response.body
    end
  end
end
