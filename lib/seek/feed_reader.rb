require 'feedjira'

module Seek
  class FeedReader

    #Fetches the feed entries - aggregated and ordered, for a particular category
    #the category may be either :project_news or :community_news
    def self.fetch_entries_for category
      raise ArgumentError.new("Invalid category - should be either :project_news or :community_news") unless [:project_news,:community_news].include? category

      urls = Seek::Config.send("#{category.to_s}_feed_urls")
      n = Seek::Config.send("#{category.to_s}_number_of_entries")

      feeds = urls.split(",").select{|url| !url.blank?}.collect do |url|
        begin
          Rails.cache.fetch(cache_key(url),:expires_in=>Seek::Config.home_feeds_cache_timeout.minutes) do
            get_feed(url)
          end
        rescue => e
          Rails.logger.error("Problem with feed: #{url} - #{e.message}")
          nil
        end
      end
      feeds.compact!

      filter_feeds_entries_with_chronological_order(feeds, n)
      
    end

    #deletes the cache directory, along with any files in it
    def self.clear_cache
      urls = Seek::Config.project_news_feed_urls.split(",").select{|url| !url.blank?}
      urls = urls | Seek::Config.community_news_feed_urls.split(",").select{|url| !url.blank?}
      urls.each do |url|
        Rails.cache.delete(cache_key(url))
      end
    end

    def self.cache_key feed_url
      #use md5 to keep the key short - highly unlikely to be a collision
      key = Digest::MD5.hexdigest(feed_url.strip)
      "news-feed-#{key}"
    end
  
    private


    def self.get_feed feed_url

      unless feed_url.blank?
        #trim the url element
        feed_url.strip!
        feed = Feedjira::Feed.fetch_and_parse(feed_url)
        raise "Error reading feed for #{feed_url} error #{feed}" if feed.is_a?(Numeric)
        feed
      end
    end

    def self.filter_feeds_entries_with_chronological_order feeds, number_of_entries=10
      filtered_entries = []
      unless feeds.blank?
        feeds.each do |feed|
           entries = feed.entries || []
           #concat the source of the entry in the entry title, used later on to display

           entries.each do |entry|
             class << entry
               attr_accessor :feed_title
             end
             entry.feed_title = feed.title
           end

           filtered_entries |= entries.take(number_of_entries) if entries
          end
      end
      filtered_entries.sort do |a,b|
        date_b = nil
        date_b = b.try(:updated) if b.respond_to?(:updated)
        date_b ||= b.try(:published) if b.respond_to?(:published)
        date_b ||= b.try(:last_modified) if b.respond_to?(:last_modified)
        date_b ||= 10.year.ago

        date_a = a.try(:updated) if a.respond_to?(:updated)
        date_a ||= a.try(:published) if a.respond_to?(:published)
        date_a ||= a.try(:last_modified) if a.respond_to?(:last_modified)
        date_a ||= 10.year.ago

        date_b <=> date_a
      end.take(number_of_entries)

    end

  end
  
end