require 'test_helper'

class RebuildTagCloudsJobTest < ActiveSupport::TestCase
  test 'perform' do
    assert_nothing_raised do
      RebuildTagCloudsJob.perform_now
    end
  end
end
