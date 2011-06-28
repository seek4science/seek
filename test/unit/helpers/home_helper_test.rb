require 'test_helper'

class HomeHelperTest < ActionView::TestCase

  test "should retrieve recently uploaded/downloaded items in the chronological order" do
    i = 0;
    while i < 10  do
      Factory :activity_log, :activity_loggable => Factory(:data_file, :policy => Factory(:public_policy)), :created_at => i.day.ago
      Factory :activity_log, :action => 'download', :activity_loggable => Factory(:data_file, :policy => Factory(:public_policy)), :created_at => i.day.ago
      i +=1
    end
    recently_uploaded_item_logs =  recently_uploaded_item_logs(1.year.ago, 10)
    recently_uploaded_item_logs.each do |recently_uploaded_item_log|
      assert_not_nil recently_uploaded_item_log.activity_loggable
      assert recently_uploaded_item_log.activity_loggable.can_view?
      assert recently_uploaded_item_log.created_at >= 1.year.ago
    end

    sorted_recently_uploaded_item_logs = recently_uploaded_item_logs.sort{|a,b| b.created_at <=> a.created_at}
    assert_equal sorted_recently_uploaded_item_logs,recently_uploaded_item_logs

    recently_downloaded_item_logs =  recently_downloaded_item_logs(1.year.ago, 10)
    recently_downloaded_item_logs.each do |recently_downloaded_item_log|
      assert_not_nil recently_downloaded_item_log.activity_loggable
      assert recently_downloaded_item_log.activity_loggable.can_view?
      assert recently_downloaded_item_log.created_at >= 1.year.ago
    end

    sorted_recently_downloaded_item_logs = recently_downloaded_item_logs.sort{|a,b| b.created_at <=> a.created_at}
    assert_equal sorted_recently_downloaded_item_logs,recently_downloaded_item_logs
  end
end
