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

    Seek::Config.project_news_feed_urls="#{stub_bbc}, #{stub_sbml}"
    Seek::Config.project_news_number_of_entries = 5
    entries = Seek::FeedReader.fetch_entries_for :project_news

    assert_equal 5, entries.count
  end

  test "check caching" do

    feed_to_use = stub_guardian
    path = Seek::FeedReader.cache_path(feed_to_use)
    assert_equal File.join(Dir.tmpdir,"seek-cache","atom-feeds",CGI::escape(feed_to_use)),path
    FileUtils.rm path if File.exists?(path)

    Seek::Config.project_news_feed_urls="#{feed_to_use}"
    Seek::FeedReader.fetch_entries_for :project_news

    assert File.exists?(path)

    #check it doesn't overwrite each time
    time = File.mtime(path)
    sleep(2)
    Seek::FeedReader.fetch_entries_for :project_news
    assert_equal time,File.mtime(path)
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

  test "handles error and ignores bad feed" do
    stub_request(:get,"http://dodgy.atom.feed").to_return(:status=>200,:body=>"<badly><formed></xml>")
    Seek::Config.project_news_feed_urls="http://dodgy.atom.feed"
    Seek::Config.project_news_number_of_entries = 5
    entries = Seek::FeedReader.fetch_entries_for :project_news
    assert entries.empty?
  end



  def stub_guardian
    mock_response_contents "http://guardian.atom.feed","guardian_atom.xml"
  end

  def stub_sbml
    mock_response_contents "http://sbml.atom.feed","sbml_atom.xml"
  end
  
  def stub_bbc
    mock_response_contents "http://bbc.atom.feed","bbc_atom.xml"
  end

end