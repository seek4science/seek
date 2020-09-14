require 'test_helper'

class ContentBlobCleanerJobTest < ActiveSupport::TestCase
  def setup
    ContentBlob.destroy_all
  end

  test 'perform' do
    to_go, keep1, keep2, keep3, keep4 = nil
    travel_to(9.hours.ago) do
      to_go = Factory(:content_blob)
      keep1 = Factory(:data_file).content_blob
      keep2 = Factory(:investigation).create_snapshot.content_blob
      keep3 = Factory(:strain_sample_type).content_blob
    end

    travel_to(7.hours.ago) do
      keep4 = Factory(:content_blob)
    end

    assert_difference('ContentBlob.count', -1) do
      ContentBlobCleanerJob.perform_now
    end

    refute ContentBlob.exists?(to_go.id)
    assert ContentBlob.exists?(keep1.id)
    assert ContentBlob.exists?(keep2.id)
    assert ContentBlob.exists?(keep3.id)
    assert ContentBlob.exists?(keep4.id)
  end
end
