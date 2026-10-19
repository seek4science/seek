class NewsFeedRefreshJob < ApplicationJob
  FEEDS = [:news].freeze

  # The recurring schedule (config/recurring.yml) runs this at the home_feeds_cache_timeout interval.
  # A bare "*/n * * * *" is only a valid cron for n in 1..59 - Fugit (used by Solid Queue) rejects a
  # larger minute step, which would stop the scheduler - so convert minute intervals of an hour or
  # more into an hour- or day-stepped expression, mirroring what `every n.minutes` produced under
  # whenever.
  def self.cron_schedule
    minutes = Seek::Config.home_feeds_cache_timeout.to_i
    minutes = 1 if minutes < 1

    if minutes < 60
      "*/#{minutes} * * * *"
    elsif (hours = (minutes / 60.0).round) < 24
      "0 */#{hours} * * *"
    else
      "0 0 */#{[(hours / 24.0).round, 31].min} * *"
    end
  end

  def perform
    return unless Seek::Config.news_enabled
    Seek::FeedReader.clear_cache

    FEEDS.each do |feed|
      Seek::FeedReader.fetch_feeds_for_category(feed) # Rebuilds caches
    end
  end
end
