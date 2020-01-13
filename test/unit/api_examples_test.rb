require 'test_helper'
require "minitest/autorun"

class ApiExamplesTest < ActiveSupport::TestCase

  require 'json-schema'
  require 'json'
  require 'yaml'

  def definitions_path
    File.join(Rails.root, 'public', 'api', 'definitions.json')
  end

  def validate_json_against_fragment (item, json, fragment)
    if File.readable?(definitions_path)
      errors = JSON::Validator.fully_validate_json(definitions_path,
                                                   json,
                                                   {:fragment => fragment})
      unless errors.empty?
        msg = 'item: '
        errors.each do |e|
          msg += e + "\n"
        end
        assert false, msg
      end
    end
  end

  examples_path = File.join(Rails.root, 'test', 'examples')

    Dir.foreach(examples_path) do |item|
      next if item == '.' or item == '..'
      example = YAML.load_file(examples_path + '/' + item)
      fragment = '#/definitions/' + item.chomp(".yml")
      fragment = fragment.sub('PostResponse', 'Response')
      fragment = fragment.sub('PatchResponse', 'Response')
      define_method("test_#{item.sub('.', '_')}") do
        validate_json_against_fragment(item, example.to_json, fragment)
      end
    end
end
