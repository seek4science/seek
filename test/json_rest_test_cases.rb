# frozen_string_literal: true

# mixin to automate testing of Rest services per controller test

require 'json-schema'
require 'json-diff'
require 'json_test_helper'

module JsonRestTestCases
  include JsonTestHelper

  def test_show_json(object = rest_api_test_object)
    className = object.class.name.dup
    className[0] = className[0].downcase
    fragment = '#/definitions/' + className + 'Response'
    get :show, params: rest_show_url_options(object).merge(id: object, format: 'json')

    if check_for_501_read_return
      assert_response :not_implemented
    else
      perform_jsonapi_checks
      validate_json_against_fragment fragment
    end
    # rescue ActionController::UrlGenerationError
    #   skip("unable to test read JSON for #{clz}")
  end

  def test_index_json
    className = @controller.class.name.dup
    className[0] = className[0].downcase
    fragment = '#/definitions/' + className.gsub('Controller', 'Response')
    get :index, params: rest_index_url_options, format: 'json'
    if check_for_501_index_return
      assert_response :not_implemented
    else
      perform_jsonapi_checks
      validate_json_against_fragment fragment
    end
    # rescue ActionController::UrlGenerationError
    #   skip("unable to test index JSON for #{clz}")
  end

  def test_json_response_code_for_not_accessible
    response_code_for_not_accessible('json')
  end

  def test_json_response_code_for_not_available
    response_code_for_not_available('json')
  end

  def edit_max_object(object); end

  def edit_min_object(object); end

  def test_json_content
    print self.class.name
    %w[min max].each do |m|
      object = get_test_object(m)
      json_file = File.join(Rails.root, 'test', 'fixtures', 'files', 'json', 'content_compare',
                            "#{m}_#{@controller.controller_name.singularize}.json")
      # parse such that backspace is eliminated and null turns to nil
      json_to_compare = JSON.parse(File.read(json_file))

      edit_max_object(object) if m == 'max'
      edit_min_object(object) if m == 'min'

      get :show, params: rest_show_url_options(object).merge(id: object, format: 'json')

      assert_response :success
      parsed_response = JSON.parse(@response.body)
      #puts JSON.pretty_generate(parsed_response)
      check_content_diff(json_to_compare, parsed_response)
    end
  end
end
