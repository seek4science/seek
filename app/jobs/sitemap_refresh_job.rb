# Regenerates the XML sitemap from config/sitemap.rb and pings search engines. Runs periodically
# via config/recurring.yml (this replaces the `sitemap:refresh` rake task that used to be scheduled
# through whenever/cron in config/schedule.rb). verbose: false mirrors the old `rake -s` invocation.
class SitemapRefreshJob < ApplicationJob
  def perform
    SitemapGenerator::Interpreter.run(verbose: false)
    SitemapGenerator::Sitemap.ping_search_engines
  end
end
