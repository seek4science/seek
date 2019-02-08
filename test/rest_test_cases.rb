# frozen_string_literal: true

# mixin to automate testing of Rest services per controller test

require 'json_rest_test_cases'

module RestTestCases
  extend ActiveSupport::Concern

  # types that should be skipped for JSON testing
  SKIPPED_JSON = %w[Sample SampleType Strain].freeze

  included do
    type_name = controller_class.controller_path.classify.to_s

    include JsonRestTestCases unless SKIPPED_JSON.include?(type_name)
  end
end
