module WriteApiTestSuite
  extend ActiveSupport::Testing::Declarative # Allows `test 'bla' do` definitions
  include ApiTestHelper

  def ignored_attributes
    ['updated_at']
  end

  ['min', 'max'].each do |m|
    test "can create #{m} resource" do
      template = load_template("post_#{m}_#{singular_name}.json.erb")
      api_post_test(template)
    end

    test "can update #{m} resource" do
      template = load_template("patch_#{m}_#{singular_name}.json.erb")
      api_patch_test(resource, template)
    end
  end

  test 'can delete resource' do
    res = resource

    # FIXME: programme factory cannot automatically be deleted, as it has projects associated
    if (res.is_a?(Programme))
      res.projects = []
      res.save!
    end

    assert_difference(-> { model.count }, -1) do
      delete member_url(res)
      assert_response :success
    end

    get member_url(res)

    assert_response :not_found
    validate_json response.body, '#/components/schemas/notFoundResponse'
  end

  test 'unauthorized user cannot update resource' do
    res = private_resource
    user_login(FactoryBot.create(:person))
    body = api_max_post_body
    body["data"]["id"] = id.to_s
    body["data"]["attributes"]["title"] = "updated by an unauthorized"

    patch member_url(res), params: body, as: :json

    assert_response :forbidden
    validate_json response.body, '#/components/schemas/forbiddenResponse'
  end

  test 'unauthorized user cannot delete resource' do
    res = private_resource
    user_login(FactoryBot.create(:person))
    assert_no_difference(-> { model.count }) do
      delete member_url(res)

      assert_response :forbidden
      validate_json response.body, '#/components/schemas/forbiddenResponse'
    end
  end

  test 'creating resource with an ID should throw error' do
    body = api_max_post_body
    body['data']['id'] = '100000000'

    assert_no_difference(-> { model.count }) do
      post collection_url, params: body, as: :json

      assert_response :unprocessable_entity
      validate_json response.body, '#/components/schemas/unprocessableEntityResponse'
      assert_match 'A POST request is not allowed to specify an id', response.body
    end
  end

  test 'creating resource with the wrong type should throw error' do
    body = api_max_post_body
    body['data']['type'] = 'wrong'

    assert_no_difference(-> { model.count }) do
      post collection_url, params: body, as: :json
      assert_response :unprocessable_entity
      validate_json response.body, '#/components/schemas/unprocessableEntityResponse'
      assert_match "The specified data:type does not match the URL's object (#{body['data']['type']} vs. #{plural_name})", response.body
    end
  end

  test 'creating resource with a missing type should throw error' do
    body = api_max_post_body
    body['data'].delete('type')

    assert_no_difference(-> { model.count }) do
      post collection_url, params: body, as: :json
      assert_response :unprocessable_entity
      validate_json response.body, '#/components/schemas/unprocessableEntityResponse'
      assert_match "A POST/PUT request must specify a data:type", response.body
    end
  end

  test 'updating resource with the wrong ID should throw error' do
    body = load_template("patch_min_#{singular_name}.json.erb", id: '100000000')

    assert_no_difference(-> { model.count }) do
      put member_url(resource), params: body, as: :json
      assert_response :unprocessable_entity
      validate_json response.body, '#/components/schemas/unprocessableEntityResponse'
      assert_match "id specified by the PUT request does not match object-id in the JSON input", response.body
    end
  end

  test 'updating resource with the wrong type should throw error' do
    body = load_template("patch_min_#{singular_name}.json.erb")
    body['data']['type'] = 'wrong'

    assert_no_difference(-> { model.count }) do
      put member_url(resource), params: body, as: :json
      assert_response :unprocessable_entity
      validate_json response.body, '#/components/schemas/unprocessableEntityResponse'
      assert_match "The specified data:type does not match the URL's object (#{body['data']['type']} vs. #{plural_name})", response.body
    end
  end

  test 'updating resource with a missing type should throw error' do
    body = load_template("patch_min_#{singular_name}.json.erb")
    body['data'].delete('type')

    assert_no_difference(-> { model.count }) do
      put member_url(resource), params: body, as: :json
      assert_response :unprocessable_entity
      validate_json response.body, '#/components/schemas/unprocessableEntityResponse'
      assert_match "A POST/PUT request must specify a data:type", response.body
    end
  end

  test 'write create example' do
    skip unless write_examples?

    template = load_template("post_max_#{singular_name}.json.erb")
    post collection_url, params: template, as: :json
    assert_response :success

    write_examples(JSON.pretty_generate(template), "#{singular_name.camelize(:lower)}Post.json")
    write_examples(JSON.pretty_generate(JSON.parse(response.body)), "#{singular_name.camelize(:lower)}PostResponse.json")
  end

  test 'write update example' do
    skip unless write_examples?

    template = load_template("patch_max_#{singular_name}.json.erb")
    patch member_url(resource), params: template, as: :json
    assert_response :success

    write_examples(JSON.pretty_generate(template), "#{singular_name.camelize(:lower)}Patch.json")
    write_examples(JSON.pretty_generate(JSON.parse(response.body)), "#{singular_name.camelize(:lower)}PatchResponse.json")
  end
end
