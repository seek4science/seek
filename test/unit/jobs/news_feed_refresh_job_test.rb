require 'test_helper'
require 'fugit'

class NewsFeedRefreshJobTest < ActiveSupport::TestCase
  test 'cron_schedule converts the cache timeout into a valid cron' do
    {
      1 => '*/1 * * * *',
      30 => '*/30 * * * *',
      59 => '*/59 * * * *',   # last value expressible as a minute step
      60 => '0 */1 * * *',    # an hour - switches to an hourly step
      90 => '0 */2 * * *',    # rounded up to two hours
      731 => '0 */12 * * *',  # ~12 hours
      1440 => '0 0 */1 * *',  # a day - switches to a daily step
      100_000 => '0 0 */31 * *' # capped at a monthly-ish day step
    }.each do |timeout, expected|
      with_config_value(:home_feeds_cache_timeout, timeout) do
        assert_equal expected, NewsFeedRefreshJob.cron_schedule
        assert Fugit.parse_cron(NewsFeedRefreshJob.cron_schedule),
               "#{NewsFeedRefreshJob.cron_schedule.inspect} is not a valid cron for timeout #{timeout}"
      end
    end
  end

  test 'cron_schedule copes with a non-positive timeout' do
    with_config_value(:home_feeds_cache_timeout, 0) do
      assert_equal '*/1 * * * *', NewsFeedRefreshJob.cron_schedule
    end
  end
end
