# Regenerates the XML sitemap from config/sitemap.rb and pings search engines. Scheduled
# periodically via config/recurring.yml. verbose: false keeps it quiet in the job logs.
class SitemapRefreshJob < ApplicationJob
  def perform
    SitemapGenerator::Interpreter.run(verbose: false)
    SitemapGenerator::Sitemap.ping_search_engines
  end
end
