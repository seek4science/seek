module ApiTestHelper
  include AuthenticatedTestHelper

  # Override me!
  def populate_extra_attributes(request_hash = {})
    {}.with_indifferent_access
  end

  # Add relationships that weren't in the original POST/PATCH request, but are in the response (such as submitter)
  def populate_extra_relationships(request_hash = {})
    extra_relationships = {}
    klass = @clz.classify.constantize
    existing = request_hash.dig('data', 'id') # Is it an existing resource, or something being created?
    add_contributor = klass.method_defined?(:contributor) && !existing
    if add_contributor
      extra_relationships[:submitter] = { data: [{ id: @current_person.id.to_s, type: 'people' }] }
    end
    if klass.method_defined?(:creators)
      people = (request_hash.dig('data', 'relationships', 'creators', 'data') || []).map(&:symbolize_keys)
      people << { id: @current_person.id.to_s, type: 'people' } if add_contributor
      if people.any?
        extra_relationships[:people] ||= {}
        extra_relationships[:people][:data] ||= []
        extra_relationships[:people][:data] += people
        extra_relationships[:people][:data] = extra_relationships[:people][:data].uniq { |d| d[:id] }
      end
    end

    extra_relationships.with_indifferent_access
  end

  def definitions_path
    File.join(Rails.root, 'public', 'api', 'definitions',
              'definitions.json')
  end

  def admin_login
    admin = Factory.create(:admin)
    @current_person = admin
    @current_user = admin.user
    # log in
    post '/session', params: { login: @current_user.login, password: generate_user_password }
  end

  def user_login(person)
    @current_person = person
    @current_user = person.user
    post '/session', params: { login: person.user.login, password: ('0' * User::MIN_PASSWORD_LENGTH) }
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

  def load_template(erb_file, hash)
    template_file = File.join(ApiTestHelper.template_dir, erb_file)
    template = ERB.new(File.read(template_file))
    namespace = OpenStruct.new(hash)
    #puts template.result(namespace.instance_eval { binding })
    json_obj = JSON.parse(template.result(namespace.instance_eval { binding }))
    return json_obj
  end

  def load_patch_template(hash)
    patch_file = File.join(Rails.root, 'test', 'fixtures',
                                     'files', 'json', 'templates', "patch_min_#{@clz}.json.erb")
    the_patch = ERB.new(File.read(patch_file))
    namespace = OpenStruct.new(hash)
    to_patch = JSON.parse(the_patch.result(namespace.instance_eval { binding }))
    return to_patch
  end

  def validate_json_against_fragment(json, fragment)
    if File.readable?(definitions_path)
      errors = JSON::Validator.fully_validate_json(definitions_path,
                                                   json,
                                                   {:fragment => fragment})
      unless errors.empty?
        msg = ""
        errors.each do |e|
          msg += e + "\n"
        end
        raise Minitest::Assertion, msg
      end
    end
  end

  def test_create
    debug = false # || true # Uncomment to enable
    begin
      create_post_values
    rescue NameError
    end

    ['min','max'].each do |m|
      if defined? @post_values
        to_post = load_template("post_#{m}_#{@clz}.json.erb", @post_values)
      else
        template_file = File.join(ApiTestHelper.template_dir, "post_#{m}_#{@clz}.json.erb")
        template = ERB.new(File.read(template_file))
        to_post = JSON.parse(template.result(binding))
      end
      puts "create, to_post #{m}", to_post if debug

      if to_post.blank?
        skip
      end

      validate_json_against_fragment to_post.to_json, "#/definitions/#{@clz.camelize(:lower)}Post"

      # debug note: responds with redirect 302 if not really logged in.. could happen if database resets and has no users
      assert_difference("#{@clz.classify}.count") do
        post collection_url, params: to_post.to_json, headers: { 'CONTENT_TYPE' => 'application/vnd.api+json' }
        if debug
          puts "==== Response ===="
          puts response.body
          puts "=================="
        end
        assert_response :success
      end

      validate_json_against_fragment response.body, "#/definitions/#{@clz.camelize(:lower)}Response"

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

  def test_should_delete_object
    begin
      obj = Factory(@clz.to_sym, contributor: @current_person)
    rescue NoMethodError
      obj = Factory(@clz.to_sym)
    end

    # FIXME: programme factory cannot automatically be deleted, as it has projects associated
    if (obj.is_a?(Programme))
      obj.projects = []
      obj.save!
    end

    assert_difference ("#{@clz.classify.constantize}.count"), -1 do
      delete member_url(obj)
      assert_response :success
    end
    get member_url(obj)
    assert_response :not_found
    validate_json_against_fragment response.body, '#/definitions/errors'
  end

  def test_unauthorized_user_cannot_update
    user_login(Factory(:person))
    obj = object_with_private_policy
    @to_post["data"]["id"] = "#{obj.id}"
    @to_post["data"]["attributes"]["title"] = "updated by an unauthorized"
    patch member_url(obj), params: @to_post
    assert_response :forbidden
    validate_json_against_fragment response.body, '#/definitions/errors'
  end

  def test_unauthorized_user_cannot_delete
    user_login(Factory(:person))
    obj = object_with_private_policy
    assert_no_difference("#{@clz.classify.constantize}.count") do
      delete member_url(obj)
      assert_response :forbidden
      validate_json_against_fragment response.body, '#/definitions/errors'
    end
  end

  def test_create_should_error_on_given_id
    post_clone = JSON.parse(JSON.generate(@to_post))
    post_clone['data']['id'] = '100000000'

    assert_no_difference ("#{@clz.classify.constantize}.count") do
      post collection_url, params: post_clone
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match 'A POST request is not allowed to specify an id', response.body
    end
  end

  def test_create_should_error_on_wrong_type
    post_clone = JSON.parse(JSON.generate(@to_post))
    post_clone['data']['type'] = 'wrong'

    assert_no_difference ("#{@clz.classify.constantize}.count") do
      post collection_url, params: post_clone
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match "The specified data:type does not match the URL's object (#{post_clone['data']['type']} vs. #{@plural_clz})", response.body
    end
  end

  def test_create_should_error_on_missing_type
    post_clone = JSON.parse(JSON.generate(@to_post))
    post_clone['data'].delete('type')

    assert_no_difference ("#{@clz.classify.constantize}.count") do
      post collection_url, params: post_clone
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match "A POST/PUT request must specify a data:type", response.body
    end
  end

  def test_update
    begin
      create_patch_values
    rescue NameError
    end

    ['min', 'max'].each do |m|
      if defined? @patch_values
        @to_patch = load_template("patch_#{m}_#{@clz}.json.erb", @patch_values)
      end

      if @to_patch.blank?
        skip
      end

      #fetch original object
      obj_id = @to_patch['data']['id']
      obj = @clz.classify.constantize.find(obj_id)
      get member_url(obj)
      assert_response :success
      #puts "after get: ", response.body
      original = JSON.parse(response.body)

      validate_json_against_fragment @to_patch.to_json, "#/definitions/#{@clz.camelize(:lower)}Patch"

      assert_no_difference("#{@clz.classify}.count") do
        patch member_url(obj), params: @to_patch.to_json, headers: { 'CONTENT_TYPE' => 'application/vnd.api+json' }
        assert_response :success
      end

      validate_json_against_fragment response.body, "#/definitions/#{@clz.camelize(:lower)}Response"

      h = JSON.parse(response.body)

      #check the post-processed attributes and relationships
      hash_comparison(populate_extra_attributes(@to_patch), h['data']['attributes'])
      hash_comparison(populate_extra_relationships(@to_patch), h['data']['relationships'])

      to_ignore = (defined? ignore_non_read_or_write_attributes) ? ignore_non_read_or_write_attributes : []
      to_ignore << 'updated_at'

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

  def test_update_should_error_on_wrong_id
    obj = Factory(("#{@clz}").to_sym)

    to_patch = load_patch_template(id: '100000000')

    assert_no_difference ("#{@clz.classify.constantize}.count") do
      put member_url(obj), params: to_patch
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match "id specified by the PUT request does not match object-id in the JSON input", response.body
    end
  end

  def test_update_should_error_on_wrong_type
    obj = Factory(("#{@clz}").to_sym)
    to_patch = load_patch_template({})
    to_patch['data']['type'] = 'wrong'

    assert_no_difference ("#{@clz.classify.constantize}.count") do
      put member_url(obj), params: to_patch
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match "The specified data:type does not match the URL's object (#{to_patch['data']['type']} vs. #{@plural_clz})", response.body
    end
  end

  def test_update_should_error_on_missing_type
    obj = Factory(("#{@clz}").to_sym)
    to_patch = load_patch_template({})
    to_patch['data'].delete('type')

    assert_no_difference ("#{@clz.classify.constantize}.count") do
      put member_url(obj), params: to_patch
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match "A POST/PUT request must specify a data:type", response.body
    end
  end

  private

  def collection_url
    "/#{@plural_clz}.json"
  end

  def member_url(obj)
    "/#{@plural_clz}/#{obj.id}.json"
  end

  ##
  # Compare `result` Hash against `source`.
  def hash_comparison(source, result)
    source.each do |key, value|
      # puts "#{key}: #{value} <==> #{result[key]}"
      deep_comparison(value, result[key], key)
    end
  end

  ##
  # Compares `result` against `source`. If `source` is a Hash, compare each each key/value pair with that in `result`. If `source` is an Array, compare each value.
  # `key` is used to generate meaningful failure messages if the assertion fails.
  def deep_comparison(source, result, key)
    if source.is_a?(Hash)
      assert result.is_a?(Hash), "#{key} was not a Hash, it was a #{result.class.name}"
      source.each do |sub_key, sub_value|
        actual = result.try(:[], sub_key)
        deep_comparison(sub_value, actual, "#{key}[#{sub_key}]")
      end
    elsif source.is_a?(Array)
      assert result.is_a?(Array), "#{key} was not an Array"
      assert_equal source.length, result.length, "#{key} length of #{result.length} was not equal to #{source.length}"
      sorted_result = result.sort_by { |e| e.is_a?(Hash) ? e['id'] : e }
      sorted_source = source.sort_by { |e| e.is_a?(Hash) ? e['id'] : e }
      sorted_source.each_with_index do |sub_value, index|
        deep_comparison(sub_value, sorted_result[index], "#{key}[#{index}]")
      end
    elsif source.nil?
      assert_nil result
    else
      assert_equal source, result, "Expected #{key} to be `#{source}` but was `#{result}`"
    end
  end

  def object_with_private_policy
    begin
      obj = Factory(("#{@clz}").to_sym, policy: Factory(:private_policy))
    rescue NoMethodError
      obj = Factory(("#{@clz}").to_sym)
    end
    obj
  end

  ##
  # Fetch errors with the given path from the given collection.
  def fetch_errors(errors, path)
    errors.select do |error|
      error.try(:[], 'source').try(:[], 'pointer') == path
    end
  end
end

