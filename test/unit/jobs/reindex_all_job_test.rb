require 'test_helper'

class ReindexAllJobTest < ActiveSupport::TestCase

  # simple sanity check, to catch interface or gem change bugs
  test 'perform' do
    FactoryBot.create(:person)
    assert_nothing_raised do
      ReindexAllJob.new('Person').perform_now
    end
  end

  test 'batch_size' do
    job = ReindexAllJob.new
    assert_equal 50, job.batch_size
    with_config_value(:reindex_all_batch_size, 5) do
      assert_equal 5, job.batch_size
    end
    with_config_value(:reindex_all_batch_size, nil) do
      assert_nil job.batch_size
    end
  end

end
