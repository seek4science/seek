require 'test_helper'

class ScheduleTest < ActionDispatch::IntegrationTest
  setup do
    @schedule = Whenever::Test::Schedule.new(file: 'config/schedule.rb')
  end

  test 'should read schedule file' do
    assert_equal 6, @schedule.jobs[:runner].count, "Should be 8: 3x Periodic Subscription, 1x ContentBlob Cleaner, 1x Newsfeed Refresh, 1x General ApplicationJob"

    # Periodic emails
    daily = @schedule.jobs[:runner].detect { |job| job[:task] == "PeriodicSubscriptionEmailJob.new('daily').queue_job" }
    weekly = @schedule.jobs[:runner].detect { |job| job[:task] == "PeriodicSubscriptionEmailJob.new('weekly').queue_job" }
    monthly = @schedule.jobs[:runner].detect { |job| job[:task] == "PeriodicSubscriptionEmailJob.new('monthly').queue_job" }
    assert daily
    assert_equal [1.day], daily[:every]
    assert weekly
    assert_equal [1.week], weekly[:every]
    assert monthly
    assert_equal [1.month], monthly[:every]

    # ContentBlob cleaner
    cleaner = @schedule.jobs[:runner].detect { |job| job[:task] == "ContentBlobCleanerJob.perform_later" }
    assert cleaner
    assert_equal [ContentBlobCleanerJob::GRACE_PERIOD], cleaner[:every]

    # Newsfeed refresh
    news_refresh = @schedule.jobs[:runner].detect { |job| job[:task] == "NewsFeedRefreshJob.set(priority: 3).perform_later" }
    assert news_refresh
    assert_equal [Seek::Config.home_feeds_cache_timeout.minutes], news_refresh[:every]
    with_config_value(:home_feeds_cache_timeout, 731) do
      reloaded_schedule = Whenever::Test::Schedule.new(file: 'config/schedule.rb')
      news_refresh = reloaded_schedule.jobs[:runner].detect { |job| job[:task] == "NewsFeedRefreshJob.set(priority: 3).perform_later" }
      assert news_refresh
      assert_equal [731.minutes], news_refresh[:every]
    end

    # General
    general = @schedule.jobs[:runner].detect { |job| job[:task] == "ApplicationJob.queue_timed_jobs" }
    assert general
    assert_equal [10.minutes], general[:every]
  end

  test 'executes tasks in schedule' do
    # Executes all the tasks to see if any of them throw error
    with_config_value(:email_enabled, true) do
      with_config_value(:openbis_enabled, true) do
        assert_nothing_raised do
          @schedule.jobs[:runner].each { |job| instance_eval job[:task] }
        end
      end
    end
  end

  test 'executes tasks in schedule and runs jobs' do
    # Executes all the tasks, and also runs the jobs to see if any of them throw errors
    with_config_value(:email_enabled, true) do
      with_config_value(:openbis_enabled, true) do
        perform_enqueued_jobs do
          assert_nothing_raised do
            @schedule.jobs[:runner].each { |job| instance_eval job[:task] }
          end
        end
      end
    end
  end
end
