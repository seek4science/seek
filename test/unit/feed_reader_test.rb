require 'test_helper'


class FeedReaderTest < ActiveSupport::TestCase

  ATOM_FEED = "http://feeds.feedburner.com/co/luEY"
  ATOM_FEED2 = "http://www.google.com/reader/public/atom/user%2F02837181562898136579%2Fbundle%2Fsbml.org%20news"
  ATOM_FEED3 = "http://feeds.feedburner.com/co/aVFK"

  def setup
    @old_project_news = Seek::Config.project_news_feed_urls
    @old_project_num_entries = Seek::Config.project_news_number_of_entries
  end

  def teardown
    Seek::Config.project_news_number_of_entries = @old_project_num_entries
    Seek::Config.project_news_feed_urls = @old_project_news
  end
  
  test "fetch atom entries" do
    Seek::Config.project_news_feed_urls="#{ATOM_FEED}, #{ATOM_FEED2}"
    Seek::Config.project_news_number_of_entries = 5
    entries = Seek::FeedReader.fetch_entries_for :project_news

    assert_equal 5, entries.count
  end

  test "check caching" do
    feed_to_use = ATOM_FEED3
    path = Seek::FeedReader.cache_path(feed_to_use)
    assert_equal File.join(Dir.tmpdir,"seek-cache","atom-feeds",CGI::escape(feed_to_use)),path
    FileUtils.rm path if File.exists?(path)

    Seek::Config.project_news_feed_urls="#{feed_to_use}"
    Seek::FeedReader.fetch_entries_for :project_news

    assert File.exists?(path)
  end

  test "clear cache" do
    dir = File.join(Dir.tmpdir,"seek-cache","atom-feeds")

    FileUtils.mkdir_p dir unless File.exists?(dir)

    #stick a file in there to make sure it handles directory with files in
    f=open(File.join(dir,"test-file"),"w+")
    f.write("some info")
    f.close
    
    Seek::FeedReader.clear_cache
    assert !File.exists?(dir)
  end
end