# frozen_string_literal: true

# mixin to automate testing of Rest services per controller test

require 'xml_rest_test_cases'
require 'json_rest_test_cases'

module RestTestCases
  extend ActiveSupport::Concern

  # types that should be skipped for XML testing
  SKIPPED_XML = %w[Programme Sample SampleType ContentBlob].freeze

  # types that should be skipped for JSON testing
  SKIPPED_JSON = %w[Sample SampleType Strain].freeze

  included do
    type_name = controller_class.controller_path.classify.to_s

    include XmlRestTestCases unless SKIPPED_XML.include?(type_name)

    include JsonRestTestCases unless SKIPPED_JSON.include?(type_name)
  end
end
