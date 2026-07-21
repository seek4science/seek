require 'test_helper'
require 'minitest/mock'

class SitemapRefreshJobTest < ActiveSupport::TestCase
  test 'regenerates the sitemap and pings search engines' do
    ran = false
    pinged = false

    SitemapGenerator::Interpreter.stub(:run, ->(*) { ran = true }) do
      SitemapGenerator::Sitemap.stub(:ping_search_engines, ->(*) { pinged = true }) do
        SitemapRefreshJob.perform_now
      end
    end

    assert ran, 'expected the sitemap to be regenerated'
    assert pinged, 'expected search engines to be pinged'
  end

  test 'uses the default queue' do
    assert_equal QueueNames::DEFAULT, SitemapRefreshJob.new.queue_name
  end
end
