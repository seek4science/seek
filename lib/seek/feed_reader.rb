module Seek
  class FeedReader

    #Fetches the feed entires - aggregated and ordered, for a particular category
    #the category may be either :project_news or :community_news
    def self.fetch_entries_for category
      raise ArgumentError.new("Invalid category - should be either :project_news or :community_news") unless [:project_news,:community_news].include? category

      urls = Seek::Config.send("#{category.to_s}_feed_urls")
      n = Seek::Config.send("#{category.to_s}_number_of_entries")

      feeds = urls.split(",").select{|url| !url.blank?}.collect{|url| get_feed(url)}

      filter_feeds_entries_with_chronological_order(feeds, n)
      
    end
  
    private

    def self.get_feed feed_url=nil
      unless feed_url.blank?
        #trim the url element
        feed_url.strip!
        begin
          feed = Atom::Feed.load_feed(URI.parse(feed_url))
        rescue
          feed = nil
        end
        feed
      end
    end

    def self.filter_feeds_entries_with_chronological_order feeds, number_of_entries=10
      filtered_entries = []
      unless feeds.blank?
        feeds.each do |feed|
           entries = try_block{feed.entries}
           #concat the source of the entry in the entry title, used later on to display
           unless entries.blank?
             entries.each{|entry| entry.title<< "***#{feed.title}" if entry.title}
           end
           filtered_entries |= entries.take(number_of_entries) if entries
        end
      end
      filtered_entries.sort {|a,b| (try_block{b.updated} || try_block{b.published} || try_block{b.last_modified} || 10.year.ago) <=> (try_block{a.updated} || try_block{a.published} || try_block{a.last_modified} || 10.year.ago)}.take(number_of_entries)
    end

  end
  
end