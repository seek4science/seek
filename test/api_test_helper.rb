module ApiTestHelper
  DEBUG = false # || true

  include AuthenticatedTestHelper

  def model
    @_model ||= self.class.name.split('ApiTest').first.constantize
  end

  def resource
    instance_variable_get("@#{model.model_name.singular}")
  end

  def private_resource
    res = resource
    res.update_column(:policy_id, FactoryBot.create(:private_policy).id) if res.respond_to?(:policy)
    res
  end

  def current_person
    @current_user&.person
  end

  def plural_name
    model.model_name.plural
  end

  def singular_name
    model.model_name.singular
  end

  def api_get_test(template, res)
    get member_url(res), as: :json
    assert_response :success

    validate_json response.body, "#/components/schemas/#{singular_name.camelize(:lower)}Response"

    expected = template
    actual = JSON.parse(response.body)

    if DEBUG
      puts "Expected:\n #{expected.inspect}\n"
      puts "Actual:\n #{actual.inspect}"
    end

    hash_comparison(expected, actual)
  end

  def api_post_test(template)
    expected = template
    validate_json template.to_json, "#/components/schemas/#{singular_name.camelize(:lower)}Post"

    # debug note: responds with redirect 302 if not really logged in.. could happen if database resets and has no users
    assert_difference(-> { model.count }, 1) do
      post collection_url, params: template, as: :json
      assert_response :success
    end

    validate_json response.body, "#/components/schemas/#{singular_name.camelize(:lower)}Response"

    actual = JSON.parse(response.body)

    expected['data']['attributes'] ||= {}
    expected['data']['attributes'].except!(*ignored_attributes)
    expected['data']['attributes'].merge!(populate_extra_attributes(template))
    expected['data']['relationships'] ||= {}
    expected['data']['relationships'].merge!(populate_extra_relationships(template))

    if DEBUG
      puts "Expected:\n #{expected.inspect}\n"
      puts "Actual:\n #{actual.inspect}"
    end

    hash_comparison(expected['data']['attributes'], actual['data']['attributes'])
    hash_comparison(expected['data']['relationships'], actual['data']['relationships'])
  end

  def api_patch_test(resource, template)
    get member_url(resource)
    assert_response :success
    expected = JSON.parse(response.body)

    validate_json template.to_json, "#/components/schemas/#{singular_name.camelize(:lower)}Patch"

    assert_no_difference(-> { model.count }) do
      patch member_url(resource), params: template, as: :json
      assert_response :success
    end

    validate_json response.body, "#/components/schemas/#{singular_name.camelize(:lower)}Response"

    actual = JSON.parse(response.body)

    expected['data']['attributes'].merge!(template['data']['attributes'] || {})
    expected['data']['attributes'].except!(*ignored_attributes)
    expected['data']['attributes'].merge!(populate_extra_attributes(template))
    expected['data']['relationships'].merge!(template['data']['relationships'] || {})
    expected['data']['relationships'].merge!(populate_extra_relationships(template))

    expected['data']['attributes'].delete(expected['data']['attributes'].keys.shuffle.first) if rand > 0.5

    if DEBUG
      puts "Expected:\n #{expected.inspect}\n"
      puts "Actual:\n #{actual.inspect}"
    end

    hash_comparison(expected['data']['attributes'], actual['data']['attributes'])
    hash_comparison(expected['data']['relationships'], actual['data']['relationships'])
  end

  # Add attributes that weren't in the original POST/PATCH request, but are in the response
  def populate_extra_attributes(request_hash)
    extra_attributes = HashWithIndifferentAccess.new

    creators = request_hash.dig('data', 'relationships', 'creators', 'data') || []
    if creators.any?
      extra_attributes[:creators] = creators.map do |c|
        p = Person.includes(:institutions).find_by_id(c['id'])
        if p
          {
            profile: "/people/#{p.id}",
            family_name: p.last_name,
            given_name: p.first_name,
            affiliation: p.institutions.map(&:title).join(', '),
            orcid: p.orcid
          }
        end
      end.compact
    end

    extra_attributes
  end

  # Add relationships that weren't in the original POST/PATCH request, but are in the response (such as submitter)
  def populate_extra_relationships(request_hash)
    extra_relationships = HashWithIndifferentAccess.new

    existing = request_hash.dig('data', 'id') # Is it an existing resource, or something being created?
    add_contributor = model.method_defined?(:contributor) && !existing
    if add_contributor
      extra_relationships[:submitter] = { data: [{ id: current_person.id.to_s, type: 'people' }] }
    end

    # Add implicit study/investigation relationships
    unless model == SampleType # SampleTypes do not have studies and investigations for some reason
      assay_ids = (request_hash.dig('data', 'relationships', 'assays', 'data') || []).map { |h| h['id'] }
      study_ids = (request_hash.dig('data', 'relationships', 'studies', 'data') || []).map { |h| h['id'] }
      assays = Assay.includes(:study).where(id: assay_ids).to_a
      studies = Study.includes(:investigation).where(id: study_ids).to_a
      if assays.any?
        extra_relationships[:studies] ||= {}
        extra_relationships[:studies][:data] = (studies | assays.map(&:study)).map { |s| { id: s.id.to_s, type: 'studies' } }
      end

      if assays.any? || studies.any?
        extra_relationships[:investigations] ||= {}
        extra_relationships[:investigations][:data] = (studies.map(&:investigation) | assays.map(&:investigation)).map { |i| { id: i.id.to_s, type: 'investigations' } }
      end
    end

    extra_relationships
  end

  def definitions_path
    File.join(Rails.root, 'public', 'api', 'definitions', 'openapi-v3-resolved.json')
  end

  def admin_login
    admin = FactoryBot.create(:admin)
    @current_user = admin.user
    # log in
    post '/session', params: { login: @current_user.login, password: generate_user_password }
  end

  def user_login(person = FactoryBot.create(:person))
    @current_user = person.user
    post '/session', params: { login: person.user.login, password: ('0' * User::MIN_PASSWORD_LENGTH) }
  end

  def id
    resource.id
  end

  def load_get_template(erb_file, res) # `res` parameter is used via binding, despite appearing unused.
    template_file = File.join(Rails.root, 'test', 'fixtures', 'json', 'responses', erb_file)
    template = ERB.new(File.read(template_file))
    b = binding
    JSON.parse(template.result(b))
  end

  def load_template(erb_file, hash = nil)
    template_file = File.join(Rails.root, 'test', 'fixtures', 'json', 'requests', erb_file)
    template = ERB.new(File.read(template_file))
    b = binding
    hash ||= {}
    hash.each do |k, v|
      b.local_variable_set(k, v)
    end
    JSON.parse(template.result(b))
  end

  def validate_json(json, fragment = nil)
    begin
      opts = {}
      opts[:fragment] = fragment if fragment
      errors = JSON::Validator.fully_validate_json(definitions_path, json, opts)
      raise Minitest::Assertion, errors.join("\n") unless errors.empty?
    rescue JSON::Schema::SchemaError => e
      if e.message.start_with?("Invalid fragment resolution for :fragment option")
        warn "#{fragment} is missing from API spec, skipping validation"
      else
        raise e
      end
    end
  end

  def api_max_post_body
    load_template("post_max_#{singular_name}.json.erb")
  end

  def write_examples?
    ENV['SEEK_WRITE_EXAMPLES']
  end

  def write_examples(json, path)
    File.write(File.join(Rails.root, 'public', 'api', 'examples', path), json)
  end

  private

  def collection_url
    polymorphic_url(model, format: :json)
  end

  def member_url(res)
    polymorphic_url(res, format: :json)
  end

  ##
  # Compare `actual` Hash against `expected`.
  def hash_comparison(expected, actual)
    expected.each do |key, value|
      deep_comparison(value, actual[key], key)
    end
  end

  ##
  # Compares `result` against `expected`. If `expected` is a Hash, compare each each key/value pair with that in `result`. If `expected` is an Array, compare each value.
  # `key` is used to generate meaningful failure messages if the assertion fails.
  def deep_comparison(expected, actual, key)
    if expected.is_a?(Hash)
      assert actual.is_a?(Hash), "#{key} was not a Hash, it was a #{actual.class.name}"
      expected.each do |expected_key, expected_value|
        actual_value = actual.try(:[], expected_key)
        deep_comparison(expected_value, actual_value, "#{key}[#{expected_key}]")
      end
    elsif expected.is_a?(Array)
      assert actual.is_a?(Array), "#{key} was not an Array, it was a #{actual.class.name}"
      assert_equal expected.length, actual.length, "#{key} length of #{actual.length} was not equal to #{expected.length}"
      sorted_actual = actual.sort_by { |e| e.is_a?(Hash) ? e['id'] || 'ZZZZ' : e }
      sorted_expected = expected.sort_by { |e| e.is_a?(Hash) ? e['id'] || 'ZZZZ' : e }
      sorted_expected.each_with_index do |sub_value, index|
        deep_comparison(sub_value, sorted_actual[index], "#{key}[#{index}]")
      end
    elsif expected.nil?
      assert_nil actual, "Expected #{key} to be nil but was `#{actual}`"
    else
      assert_equal expected, actual, "Expected #{key} to be `#{expected}` but was `#{actual}`"
    end
  end

  ##
  # Fetch errors with the given path from the given collection.
  def fetch_errors(errors, path)
    errors.select do |error|
      error.try(:[], 'source').try(:[], 'pointer') == path
    end
  end
end

