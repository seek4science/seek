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
          get_feed(url)
        rescue => e
          Rails.logger.warn("Problem with feed: #{url} - #{e.message}")
          nil
        end
      end
      feeds.delete(nil)

      filter_feeds_entries_with_chronological_order(feeds, n)
      
    end

    #the cache file for a given feed url
    def self.cache_path(url)
      File.join(cache_dir,CGI::escape(url))
    end

    #the directory used to contain the cached files
    def self.cache_dir
      if Rails.env=="test"
        dir = File.join(Dir.tmpdir,"seek-cache","atom-feeds")
      else
        dir = File.join(Rails.root,"tmp","cache","atom-feeds")
      end
      FileUtils.mkdir_p dir if !File.exists?(dir)
      dir
    end

    #deletes the cache directory, along with any files in it
    def self.clear_cache
      FileUtils.rm_rf cache_dir
    end

    def self.cache_timeout
      2.minutes.ago
    end
  
    private

    def self.get_feed feed_url

      unless feed_url.blank?
        #trim the url element
        feed_url.strip!

        src = select_feed_source feed_url
        feed = Atom::Feed.load_feed(src)
        cache_feed(feed_url,feed.to_xml) unless src.is_a?(File)

        feed
      end
    end

    # Selects either an IO object the a cached version of the feed, or a URI object
    # This is determined by whether upon whether the cached copy is more than #cached_timeout old (currently defaults to 2 minutes)
    # The cache is never used when running in DEVELOPMENT environment
    def self.select_feed_source feed_url
      source = URI.parse(feed_url)
      unless Rails.env=="development"
        source = check_cache(feed_url) || source
      end
      source
    end

    def self.check_cache url
      path=cache_path(url)
      if File.exists?(path) && File.mtime(path) > cache_timeout
        open(path)
      else
        nil
      end
    end

    def self.cache_feed url,xml
      path=cache_path(url)
      f=open(path,"w+")
      f.write(xml)
      f.close
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
             entry.feed_title = feed.title || feed.subtitle
           end

           filtered_entries |= entries.take(number_of_entries) if entries
          end
      end
      filtered_entries.sort {|a,b| (try_block{b.updated} || try_block{b.published} || try_block{b.last_modified} || 10.year.ago) <=> (try_block{a.updated} || try_block{a.published} || try_block{a.last_modified} || 10.year.ago)}.take(number_of_entries)

    end

  end
  
end