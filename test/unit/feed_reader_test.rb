require 'test_helper'

class FeedReaderTest < ActiveSupport::TestCase
  def setup
    @old_project_news = Seek::Config.project_news_feed_urls
    @old_project_num_entries = Seek::Config.project_news_number_of_entries
  end

  def teardown
    Seek::Config.project_news_number_of_entries = @old_project_num_entries
    Seek::Config.project_news_feed_urls = @old_project_news
  end

  test 'fetch atom entries' do
    VCR.use_cassette('feedjira/get_reddit_feed') do
      VCR.use_cassette('feedjira/get_fairdom_feed') do
        Seek::Config.project_news_feed_urls = "#{reddit_feed_url}, #{fairdom_news_feed_url}"
        Seek::Config.project_news_number_of_entries = 5
        entries = Seek::FeedReader.fetch_entries_for :project_news

        assert_equal 5, entries.count
      end
    end
  end

  test 'check caching' do
    Seek::FeedReader.clear_cache
    feed_to_use = reddit_feed_url

    key = Seek::FeedReader.cache_key(feed_to_use)
    refute_nil key
    assert !Rails.cache.exist?(key)

    VCR.use_cassette('feedjira/get_reddit_feed') do
      Seek::Config.project_news_feed_urls = "#{feed_to_use}"
      Seek::FeedReader.fetch_entries_for :project_news
    end


    assert Rails.cache.exist?(key)

    Seek::FeedReader.clear_cache
    assert !Rails.cache.exist?(key), 'cache should have been cleared'
  end

  test 'check denylisting' do
    assert_nil Seek::Config.denylisted_feeds
    url = 'http://dodgyfeed.atom'
    stub_request(:get, url).to_return(status: 500, body: '')
    Seek::Config.project_news_feed_urls = url
    assert_equal [url], Seek::FeedReader.determine_feed_urls(:project_news)
    entries = Seek::FeedReader.fetch_entries_for :project_news
    assert_empty entries
    denied = Seek::Config.denylisted_feeds
    refute_nil denied[url]
    assert denied[url].is_a?(Time)
    assert_empty Seek::FeedReader.determine_feed_urls(:project_news)

    travel_to(Time.now + Seek::FeedReader::DENYLIST_TIME + 1.minute) do
      assert_equal [url], Seek::FeedReader.determine_feed_urls(:project_news)
      denied = Seek::Config.denylisted_feeds
      assert_nil denied[url]
    end

    Seek::Config.denylisted_feeds = nil
  end

  test 'handles error and ignores bad feed' do
    XML::Error.set_handler(&XML::Error::QUIET_HANDLER)

    VCR.use_cassette('feedjira/get_bad_feed') do
      Seek::Config.project_news_feed_urls = "#{bad_feed_url}"
      Seek::Config.project_news_number_of_entries = 5
      entries = Seek::FeedReader.fetch_entries_for :project_news
      assert entries.empty?
    end
  end

  def fairdom_news_feed_url
    'https://fair-dom.org/news.xml'
  end

  def reddit_feed_url
    'https://www.reddit.com/r/ruby.rss'
  end

  def bad_feed_url
    'http://badfeed.com/rss'
  end

end
