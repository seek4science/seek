# frozen_string_literal: true
# mixin to automate testing of Rest services per controller test

require 'json-schema'
require 'json-diff'

module JsonTestHelper
  JSONAPI_SCHEMA_FILE_PATH = File.join(Rails.root, 'public', 'api', 'jsonapi-schema-v1')

  def definitions_path
    File.join(Rails.root, 'public', 'api', 'definitions', 'definitions.json')
  end

  def validate_json(path)
    if File.readable?(path)
      errors = JSON::Validator.fully_validate_json(path, @response.body)
      unless errors.empty?
        msg = ''
        errors.each do |e|
          msg += e + "\n"
        end
        raise Minitest::Assertion, msg
      end
    end
  end

  def validate_json_against_fragment(fragment)
    if File.readable?(definitions_path)
      errors = JSON::Validator.fully_validate_json(definitions_path,
                                                   @response.body,
                                                   fragment: fragment)
      unless errors.empty?
        msg = ''
        errors.each do |e|
          msg += e + "\n"
        end
        raise Minitest::Assertion, msg
      end
    end
  end

  def check_content_diff(json1, json2)
    plural_obj = @controller.controller_name.pluralize
    base = json2['data']['meta']['base_url']
    diff = JsonDiff.diff(json1, json2, moves: false)

    diff.reverse_each do |el|
      # the self link must start with the pluralized controller's name (e.g. /people)
      if el['path'] =~ /self/
        if plural_obj == 'collection_items' # ugh
          assert_match /\/collections\/\d+\/items\/\d+/, el['value']
        else
          assert_match /\/#{plural_obj}\/\d+/, el['value']
        end
        # url in version, e.g.  base_url/data_files/877365356?version=1
      elsif el['path'] =~ /versions\/\d+\/url/
        assert_match /#{base}\/#{plural_obj}\/\d+\?version=\d+/, el['value']
        diff.delete(el)
        # link in content blob, e.g.  base_url/data_files/877365356/content_blobs/343567275
      elsif el['path'] =~ /content_blobs\/\d+\/link/
        assert_match /#{base}\/#{plural_obj}\/\d+\/content_blobs\/\d+/, el['value']
        diff.delete(el)
      elsif el['path'] =~ /avatar/
        assert_match /^\/#{plural_obj}\/\d+\/avatars\/\d+/, el['value']
        diff.delete(el)
      elsif el['path'] =~ /policy/
        diff.delete(el)
      elsif el['path'] =~ /attributes\/creators\/\d+\/profile|given_name|family_name|orcid|affiliation/
        assert_equal 'replace', el['op'], "Unexpected difference in creator: #{el.inspect}"
        diff.delete(el)
      end
    end

    diff.delete_if do |el|
      el['path'] =~ /\/id|created|updated|modified|uuid|jsonapi|self|download|md5sum|sha1sum|project_id|position_id|tags|members|links\/items/
    end

    assert_equal [], diff
  end

  def perform_jsonapi_checks
    assert_response :success
    assert_equal 'application/vnd.api+json', @response.media_type
    assert JSON::Validator.validate(JSONAPI_SCHEMA_FILE_PATH, @response.body), 'Response did not validate against JSON-API schema'
  end

  # check if this current controller type doesn't support read
  def check_for_501_read_return
    clz = @controller.controller_model.to_s
    %w[Strain].include?(clz)
  end

  # check if this current controller type doesn't support index
  def check_for_501_index_return
    clz = @controller.controller_model.to_s
    %w[Sample Strain].include?(clz)
  end

  # m corresponds to 'min'/'max'
  def get_test_object(m)
    type = @controller.controller_name.classify
    opts = type.constantize.method_defined?(:policy) ? { policy: Factory(:publicly_viewable_policy) } : {}
    opts[:publication_type] = Factory(:journal) if type.constantize.method_defined?(:publication_type)

    # some factories require a user to be logged in to create, such as those with tags
    User.with_current_user(User.current_user || Factory(:person).user) do
      Factory("#{m}_#{type.underscore}".to_sym, opts)
    end
  end

  def response_code_for_not_available(format)
    id = (@controller.controller_model.maximum(:id) || 0) + 1357

    url_opts = rest_show_url_options.merge(id: id, format: format)

    logout

    get :show, params: url_opts
    assert_response :not_found
  end

  def response_code_for_not_accessible(format)
    clz = @controller.controller_model
    if clz.respond_to?(:authorization_supported?) && clz.authorization_supported?
      itemname = @controller.controller_name.singularize.underscore
      item = Factory itemname.to_sym, policy: Factory(:private_policy)
      url_opts = rest_show_url_options.merge(id: item.id, format: format)
      logout

      get :show, params: url_opts
      assert_response :forbidden
    end
  end

  def rest_show_url_options(_object = rest_api_test_object)
    {}
  end

  def rest_index_url_options()
    {}
  end
end
