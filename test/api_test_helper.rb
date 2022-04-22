module ApiTestHelper
  include AuthenticatedTestHelper

  def plural_name
    model.model_name.plural
  end

  def singular_name
    model.model_name.singular
  end

  # Override me!
  def populate_extra_attributes(request_hash = {})
    {}.with_indifferent_access
  end

  # Add relationships that weren't in the original POST/PATCH request, but are in the response (such as submitter)
  def populate_extra_relationships(request_hash = {})
    extra_relationships = {}
    existing = request_hash.dig('data', 'id') # Is it an existing resource, or something being created?
    add_contributor = model.method_defined?(:contributor) && !existing
    if add_contributor
      extra_relationships[:submitter] = { data: [{ id: @current_person.id.to_s, type: 'people' }] }
    end
    if model.method_defined?(:creators)
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
                                     'files', 'json', 'templates', "patch_min_#{singular_name}.json.erb")
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

  private

  def collection_url
    polymorphic_url(model, format: :json)
  end

  def member_url(obj)
    polymorphic_url(obj, format: :json)
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
      assert_nil result, "Expected #{key} to be nil but was `#{result}`"
    else
      assert_equal source, result, "Expected #{key} to be `#{source}` but was `#{result}`"
    end
  end

  def object_with_private_policy
    obj = resource
    obj.update_column(:policy_id, Factory(:private_policy).id) if obj.respond_to?(:policy)
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

