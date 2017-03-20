require 'feedjira'

module Seek
  class FeedReader
    BLACKLIST_TIME = 1.day

    # Fetches the feed entries - aggregated and ordered, for a particular category
    def self.fetch_entries_for(category)
      feeds = fetch_feeds_for_category(category)

      filter_feeds_entries_with_chronological_order(feeds, Seek::Config.send("#{category}_number_of_entries"))
    end

    def self.fetch_feeds_for_category(category)
      feeds = determine_feed_urls(category).collect do |url|
        begin
          # :expires_in set 5 minutes after configured time as a fallback in case NewsFeedRefreshJob isn't running.
          Rails.cache.fetch(cache_key(url), expires_in: (Seek::Config.home_feeds_cache_timeout + 5).minutes) do
            get_feed(url)
          end
        rescue => exception
          Rails.logger.error("Problem with feed: #{url} - #{exception.message}")
          blacklist(url)
          nil
        end
      end
      feeds.compact!
      feeds
    end

    def self.blacklist(url)
      blacklisted = Seek::Config.blacklisted_feeds || {}
      blacklisted[url] = Time.now
      Seek::Config.blacklisted_feeds = blacklisted
    end

    def self.is_blacklisted?(url)
      list = Seek::Config.blacklisted_feeds || {}
      return false unless list[url]
      if list[url] < BLACKLIST_TIME.ago
        list.delete(url)
        Seek::Config.blacklisted_feeds = list
        false
      else
        true
      end
    end

    def self.determine_feed_urls(category)
      urls = Seek::Config.send("#{category}_feed_urls")
      urls.split(',').select { |url| !url.blank? && !is_blacklisted?(url) }
    end

    # deletes the cache directory, along with any files in it
    def self.clear_cache
      urls = Seek::Config.project_news_feed_urls.split(',').select { |url| !url.blank? }
      urls |= Seek::Config.community_news_feed_urls.split(',').select { |url| !url.blank? }
      urls.each do |url|
        Rails.cache.delete(cache_key(url))
      end
    end

    def self.cache_key(feed_url)
      # use md5 to keep the key short - highly unlikely to be a collision
      key = Digest::MD5.hexdigest(feed_url.strip)
      "news-feed-#{key}"
    end

    def self.get_feed(feed_url)
      unless feed_url.blank?
        # trim the url element
        feed_url.strip!
        feed = Feedjira::Feed.fetch_and_parse(feed_url)
        fail "Error reading feed for #{feed_url} error #{feed}" if feed.is_a?(Numeric)
        feed
      end
    end

    def self.filter_feeds_entries_with_chronological_order(feeds, number_of_entries = 10)
      filtered_entries = []
      unless feeds.blank?
        feeds.each do |feed|
          filtered_entries = fetch_and_filter_entries(feed, filtered_entries, number_of_entries)
        end
      end
      sort_entries(filtered_entries).take(number_of_entries)
    end

    def self.sort_entries(filtered_entries)
      filtered_entries.sort do |entry_a, entry_b|
        date_a = resolve_feed_date(entry_a)
        date_b = resolve_feed_date(entry_b)
        date_b <=> date_a
      end
    end

    def self.fetch_and_filter_entries(feed, filtered_entries, number_of_entries)
      entries = feed.entries || []

      entries.each do |entry|
        class << entry
          attr_accessor :feed_title
        end
        entry.feed_title = feed.title
      end

      filtered_entries |= entries.take(number_of_entries) if entries
      filtered_entries
    end

    def self.resolve_feed_date(entry)
      date = nil
      date = entry.try(:published) if entry.respond_to?(:published)
      date ||= entry.try(:updated) if entry.respond_to?(:updated)
      date ||= entry.try(:last_modified) if entry.respond_to?(:last_modified)
      date ||= 10.year.ago
      date
    end
  end
end
