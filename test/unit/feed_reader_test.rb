require 'test_helper'


class FeedReaderTest < ActiveSupport::TestCase

  ATOM_FEED="http://feeds.feedburner.com/co/luEY"

  def setup
    @old_project_news = Seek::Config.project_news_feed_urls
    @old_project_num_entries = Seek::Config.project_news_number_of_entries
  end

  def teardown
    Seek::Config.project_news_number_of_entries = @old_project_num_entries
    Seek::Config.project_news_feed_urls = @old_project_news
  end

  test "fetch atom entries" do

    Seek::Config.project_news_feed_urls="#{ATOM_FEED}"
    Seek::Config.project_news_number_of_entries = 3
    entries = Seek::FeedReader.fetch_entries_for :project_news

    assert_equal 3, entries.count
    
  end

end