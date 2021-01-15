class NewsFeedRefreshJob < ApplicationJob
  FEEDS = [:news].freeze

  def perform
    return unless Seek::Config.news_enabled
    Seek::FeedReader.clear_cache

    FEEDS.each do |feed|
      Seek::FeedReader.fetch_feeds_for_category(feed) # Rebuilds caches
    end
  end
end
