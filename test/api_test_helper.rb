module ApiTestHelper
  include AuthenticatedTestHelper

  def current_person
    @current_user&.person
  end

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

    extra_relationships.with_indifferent_access
  end

  def definitions_path
    File.join(Rails.root, 'public', 'api', 'definitions',
              'definitions.json')
  end

  def admin_login
    admin = Factory.create(:admin)
    @current_user = admin.user
    # log in
    post '/session', params: { login: @current_user.login, password: generate_user_password }
  end

  def user_login(person)
    @current_user = person.user
    post '/session', params: { login: person.user.login, password: ('0' * User::MIN_PASSWORD_LENGTH) }
  end

  def self.template_dir
    File.join(Rails.root, 'test', 'fixtures', 'files', 'json', 'templates')
  end

  def load_template(erb_file, hash = nil)
    hash ||= {}
    template_file = File.join(ApiTestHelper.template_dir, erb_file)
    template = ERB.new(File.read(template_file))
    hash[:r] = -> (*args) { load_template(*args).to_json }
    b = binding
    hash.each do |k, v|
      b.local_variable_set(k, v)
    end
    JSON.parse(template.result(b))
  end

  def load_patch_template(hash = {})
    load_template("patch_min_#{singular_name}.json.erb", (patch_values || {}).merge(hash))
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

