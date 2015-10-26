class NewsFeedRefreshJob < SeekJob
  FEEDS = [:project_news, :community_news]

  def perform_job(_) # ArgumentError thrown if this isn't present
    Seek::FeedReader.clear_cache

    FEEDS.each do |feed|
      Seek::FeedReader.fetch_feeds_for_category(feed) # Rebuilds caches
    end
  end

  def follow_on_job?
    true
  end

  def default_priority
    3
  end

  def follow_on_delay
    Seek::Config.home_feeds_cache_timeout.minutes
  end

  def allow_duplicate_jobs?
    false
  end

  # Need this or perform_job won't ever be called!
  def gather_items
    [nil]
  end

  # overidden to ignore_locked false by default
  def exists?(ignore_locked = false)
    super(ignore_locked)
  end

  # overidden to ignore_locked false by default
  def count(ignore_locked = false)
    super(ignore_locked)
  end

  def self.create_initial_job
    self.new.queue_job
  end
end
