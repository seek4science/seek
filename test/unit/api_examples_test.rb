require 'test_helper'
require "minitest/autorun"
require 'json-schema'
require 'json'
require 'yaml'

class ApiExamplesTest < ActiveSupport::TestCase
  include ApiTestHelper

  examples_path = File.join(Rails.root, 'public', 'api', 'examples')
    Dir.foreach(examples_path) do |item|
      next if item == '.' || item == '..' || item.end_with?('.orig')
      example = YAML.load_file(examples_path + '/' + item)
      fragment = '#/components/schemas/' + item.chomp('.json')
      fragment = fragment.sub('PostResponse', 'Response')
      fragment = fragment.sub('PatchResponse', 'Response')
      fragment = fragment.sub(/[a-zA-Z]+sResponse|peopleResponse/, 'indexResponse') unless fragment.end_with?('sampleAttributeTypesResponse')
      define_method("test_#{item.sub('.', '_')}") do
        assert_nothing_raised do
          validate_json(example.to_json, fragment)
        end
      end
    end
end
