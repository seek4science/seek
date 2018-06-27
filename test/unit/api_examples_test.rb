require 'test_helper'

class ApiExamplesTest < ActiveSupport::TestCase

  require 'json-schema'
  require 'json'
  require 'yaml'

  def definitions_path
    File.join(Rails.root, 'public', '2010', 'json', 'rest',
              'definitions.json')
  end

  def examples_path
    File.join(Rails.root, 'test', 'fixtures', 'files', 'json', 'examples')
  end

  def validate_json_against_fragment (json, fragment)
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

  test 'dummy_test' do
    Dir.foreach(examples_path) do |item|
      next if item == '.' or item == '..'
      puts item
      example = YAML.load_file(examples_path + '/' + item)
      fragment = '#/definitions/' + item.chomp(".yml")
      fragment = fragment.sub('PostResponse', 'Response')
      fragment = fragment.sub('PatchResponse', 'Response')
      validate_json_against_fragment(example.to_json, fragment)
    end
  end
end