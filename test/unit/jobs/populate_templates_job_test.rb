require 'test_helper'

class PopulateTemplatesJobTest < ActiveSupport::TestCase
  test 'perform' do
    with_config_value(:project_single_page_advanced_enabled, true) do
      assert_nothing_raised do
        PopulateTemplatesJob.perform_now
      end
    end
  end
end
