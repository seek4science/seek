require 'test_helper'
require "minitest/autorun"
require 'json-schema'
require 'json'
require 'yaml'

class ApiExamplesTest < ActiveSupport::TestCase
  include ApiTestHelper

  examples_path = File.join(Rails.root, 'public', 'api', 'examples')
    Dir.foreach(examples_path) do |item|
      next if item == '.' or item == '..'
      example = YAML.load_file(examples_path + '/' + item)
      fragment = '#/definitions/' + item.chomp('.json')
      fragment = fragment.sub('PostResponse', 'Response')
      fragment = fragment.sub('PatchResponse', 'Response')
      define_method("test_#{item.sub('.', '_')}") do
        validate_json(example.to_json, fragment)
      end
    end
end
