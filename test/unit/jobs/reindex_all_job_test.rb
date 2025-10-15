require 'test_helper'

class ReindexAllJobTest < ActiveSupport::TestCase

  # simple sanity check, to catch interface or gem change bugs
  test 'perform' do
    FactoryBot.create(:person)
    assert_nothing_raised do
      ReindexAllJob.new('Person').perform_now
    end
  end

end
