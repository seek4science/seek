require 'test_helper'

class HomesHelperTest < ActionView::TestCase

  test "should retrieve recently added/downloaded items in the chronological order" do
    n = 5
    user = Factory :user
    item = Factory(:data_file, :policy => Factory(:public_policy),:contributor=>user)

    create_logs = []

    private = Factory(:data_file,:policy => Factory(:private_policy))
    assert !private.can_view?(user)
    create_logs << Factory(:activity_log,:action=>:create,:activity_loggable => private, :created_at => 9.day.ago, :culprit=>user)
    download_logs = []
    (0...n).to_a.each do |i|
      item2 = Factory(:data_file, :policy => Factory(:public_policy),:contributor=>user)
      create_logs << Factory(:activity_log, :action=> 'create', :activity_loggable => item2, :created_at => i.day.ago, :culprit=>user)
      download_logs << Factory(:activity_log, :action => 'download', :activity_loggable => item2, :created_at => i.day.ago, :culprit=>user)
      download_logs << Factory(:activity_log, :action => 'download', :activity_loggable => item, :created_at => i.hour.ago, :culprit=>user)
    end

    recently_added_item_logs =  recently_added_item_logs(1.year.ago, n)
    recently_added_item_logs.each do |recently_added_item_log|
      assert_not_nil recently_added_item_log.activity_loggable
      assert recently_added_item_log.activity_loggable.can_view?(user)
      assert recently_added_item_log.created_at >= 1.year.ago
    end

    #test the sorting by lasted logs
    sorted_recently_added_item_logs = recently_added_item_logs.sort{|a,b| b.created_at <=> a.created_at}
    assert_equal sorted_recently_added_item_logs,recently_added_item_logs

    recently_downloaded_items = []
    recently_downloaded_item_logs =  recently_downloaded_item_logs(1.year.ago, n)
    recently_downloaded_item_logs.each do |recently_downloaded_item_log|
      assert_not_nil recently_downloaded_item_log.activity_loggable
      assert recently_downloaded_item_log.activity_loggable.can_view?(user)
      assert recently_downloaded_item_log.created_at >= 1.year.ago
      recently_downloaded_items.push recently_downloaded_item_log.activity_loggable
    end

    sorted_recently_downloaded_item_logs = recently_downloaded_item_logs.sort{|a,b| b.created_at <=> a.created_at}
    assert_equal sorted_recently_downloaded_item_logs,recently_downloaded_item_logs

    #test the recently_downloaded_items dont contain the duplication
    assert_equal recently_downloaded_items,  recently_downloaded_items.uniq
    download_logs = download_logs.select{|log| log.activity_loggable == item}.sort{|a,b| b.created_at <=> a.created_at}

    #test the lasted recenly_downloaded_log is taken
    recently_downloaded_item_logs = recently_downloaded_item_logs.select{|log| log.activity_loggable == item}
    assert_equal 1, recently_downloaded_item_logs.count
    assert_equal recently_downloaded_item_logs.first, download_logs.first
  end
end
