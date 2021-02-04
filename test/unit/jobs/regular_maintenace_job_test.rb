require 'test_helper'

class RegularMaintenaceJobTest < ActiveSupport::TestCase
  def setup
    ContentBlob.destroy_all
  end

  test 'run period' do
    assert_equal 8.hours, RegularMaintenanceJob::RUN_PERIOD
  end

  test 'cleans content blobs' do
    assert_equal 8.hours, RegularMaintenanceJob::BLOB_GRACE_PERIOD
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
      RegularMaintenanceJob.perform_now
    end

    refute ContentBlob.exists?(to_go.id)
    assert ContentBlob.exists?(keep1.id)
    assert ContentBlob.exists?(keep2.id)
    assert ContentBlob.exists?(keep3.id)
    assert ContentBlob.exists?(keep4.id)
  end

  test 'remove old unregistered users' do
    assert_equal 1.week,RegularMaintenanceJob::USER_GRACE_PERIOD
    to_go, keep1, keep2 = nil
    travel_to(2.weeks.ago) do
      to_go = Factory(:brand_new_user)
      assert_nil to_go.person
      keep1 = Factory(:person).user
    end

    travel_to(5.days.ago) do
      keep2 = Factory(:brand_new_user)
      assert_nil keep2.person
    end

    assert_difference('User.count',-1) do
      RegularMaintenanceJob.perform_now
    end

    refute User.exists?(to_go.id)
    assert User.exists?(keep1.id)
    assert User.exists?(keep2.id)
  end
end
