require 'test_helper'

class PopulateTemplatesJobTest < ActiveSupport::TestCase
  test 'perform' do
    with_config_value(:isa_json_compliance_enabled, true) do
      assert_nothing_raised do
        PopulateTemplatesJob.perform_now
      end
    end
  end
end
