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
  
  test "fetch atom entries" do

    Seek::Config.project_news_feed_urls="#{uri_to_bbc_feed}, #{uri_to_sbml_feed}"
    Seek::Config.project_news_number_of_entries = 5
    entries = Seek::FeedReader.fetch_entries_for :project_news

    assert_equal 5, entries.count
  end

  test "check caching" do
    Seek::FeedReader.clear_cache
    feed_to_use = uri_to_guardian_feed

    key = Seek::FeedReader.cache_key(feed_to_use)
    refute_nil key
    assert !Rails.cache.exist?(key)

    Seek::Config.project_news_feed_urls="#{feed_to_use}"
    Seek::FeedReader.fetch_entries_for :project_news

    assert Rails.cache.exist?(key)

    Seek::FeedReader.clear_cache
    assert !Rails.cache.exist?(key),"cache should have been cleared"
  end

  test "handles error and ignores bad feed" do
    XML::Error.set_handler(&XML::Error::QUIET_HANDLER)
    Seek::Config.project_news_feed_urls="#{uri_to_bad_feed}}"
    Seek::Config.project_news_number_of_entries = 5
    entries = Seek::FeedReader.fetch_entries_for :project_news
    assert entries.empty?
  end



  def uri_to_guardian_feed
    uri_to_feed "guardian_atom.xml"
  end

  def uri_to_sbml_feed
    uri_to_feed "sbml_atom.xml"
  end
  
  def uri_to_bbc_feed
    uri_to_feed("bbc_atom.xml")
  end

  def uri_to_bad_feed
    uri_to_feed("bad_atom.xml")
  end

  def uri_to_feed filename
    path = File.join(Rails.root,"test","fixtures","files","mocking",filename)
    URI.join('file:///',path).to_s
  end

end