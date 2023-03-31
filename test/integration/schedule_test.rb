require 'test_helper'

class ScheduleTest < ActionDispatch::IntegrationTest
  setup do
    @schedule = Whenever::Test::Schedule.new(file: 'config/schedule.rb')
  end

  test 'should read schedule file' do
    runners = @schedule.jobs[:runner]

    # Periodic emails
    daily = pop_task(runners, "PeriodicSubscriptionEmailJob.new('daily').queue_job")
    weekly = pop_task(runners, "PeriodicSubscriptionEmailJob.new('weekly').queue_job")
    monthly = pop_task(runners, "PeriodicSubscriptionEmailJob.new('monthly').queue_job")
    assert daily
    assert_equal [1.day, { at: '12:00am' }], daily[:every]
    assert weekly
    assert_equal [1.week, { at: '12:00am' }], weekly[:every]
    assert monthly
    assert_equal [1.month, { at: '12:00am' }], monthly[:every]

    # RegularMaintenanceJob
    regular = pop_task(runners, "RegularMaintenanceJob.perform_later")
    assert regular
    assert_equal [RegularMaintenanceJob::RUN_PERIOD, { at: '1:00am' }], regular[:every]

    # LifeMonitor status
    lm_status = pop_task(runners, "LifeMonitorStatusJob.perform_later")
    assert lm_status
    assert_equal [LifeMonitorStatusJob::PERIOD, { at: '2:00am' }], lm_status[:every]

    # Newsfeed refresh
    news_refresh = pop_task(runners, "NewsFeedRefreshJob.set(priority: 3).perform_later")
    assert news_refresh
    assert_equal [Seek::Config.home_feeds_cache_timeout.minutes], news_refresh[:every]

    # General
    general = pop_task(runners, "ApplicationJob.queue_timed_jobs")
    assert general
    assert_equal [10.minutes], general[:every]

    # ApplicationStatus
    app_status = pop_task(runners, "ApplicationStatus.instance.refresh")
    assert app_status
    assert_equal [1.minute], app_status[:every]

    # Galaxy::ToolMap.instance.refresh
    tool_map_refresh = pop_task(runners, "Galaxy::ToolMap.instance.refresh")
    assert tool_map_refresh
    assert_equal [1.day, { at: '3:00am' }], tool_map_refresh[:every]

    # Data dumps
    data_dump = pop_task(runners, 'Seek::BioSchema::DataDump.generate_dumps')
    assert data_dump
    assert_equal [1.day, { at: '12:10 am' }], data_dump[:every]

    assert_empty runners, "Found untested runner(s) in schedule"
  end

  test 'executes tasks in schedule' do
    # Executes all the tasks to see if any of them throw error
    with_config_value(:email_enabled, true) do
      with_config_value(:openbis_enabled, true) do
        assert_nothing_raised do
          VCR.use_cassette('galaxy/fetch_tools_trimmed') do
            VCR.use_cassette('bio_tools/fetch_galaxy_tool_names') do
              @schedule.jobs[:runner].each { |job| instance_eval job[:task] }
            end
          end
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
            VCR.use_cassette('galaxy/fetch_tools_trimmed') do
              VCR.use_cassette('bio_tools/fetch_galaxy_tool_names') do
                @schedule.jobs[:runner].each { |job| instance_eval job[:task] }
              end
            end
          end
        end
      end
    end
  end

  test 'news feed refresh changes with config' do
    with_config_value(:home_feeds_cache_timeout, 731) do
      news_refresh = Whenever::Test::Schedule.new(file: 'config/schedule.rb').jobs[:runner].detect { |job| job[:task] == "NewsFeedRefreshJob.set(priority: 3).perform_later" }
      assert_equal [Seek::Config.home_feeds_cache_timeout.minutes], news_refresh[:every]
      assert_equal [731.minutes], news_refresh[:every]
    end
  end

  test 'should offset daily job runtime by configured amount' do
    plus_43_schedule = nil
    with_config_value(:regular_job_offset, 43) do
      plus_43_schedule = Whenever::Test::Schedule.new(file: 'config/schedule.rb')
    end
    plus_43_runners = plus_43_schedule.jobs[:runner]

    minus_237_schedule = nil
    with_config_value(:regular_job_offset, -237) do
      minus_237_schedule = Whenever::Test::Schedule.new(file: 'config/schedule.rb')
    end
    minus_237_runners = minus_237_schedule.jobs[:runner]

    # For jobs that are not run daily, such as this one, which is run every 4 hours, only the minute offsets are applied.
    assert_equal [RegularMaintenanceJob::RUN_PERIOD, { at: '1:43am' }],
                 pop_task(plus_43_runners, "RegularMaintenanceJob.perform_later")[:every]
    assert_equal [RegularMaintenanceJob::RUN_PERIOD, { at: '9:03pm' }],
                 pop_task(minus_237_runners, "RegularMaintenanceJob.perform_later")[:every]

    assert_equal [LifeMonitorStatusJob::PERIOD, { at: '2:43am' }],
                 pop_task(plus_43_runners, "LifeMonitorStatusJob.perform_later")[:every]
    assert_equal [LifeMonitorStatusJob::PERIOD, { at: '10:03pm' }],
                 pop_task(minus_237_runners, "LifeMonitorStatusJob.perform_later")[:every]

    assert_equal [1.day, { at: '3:43am' }],
                 pop_task(plus_43_runners, "Galaxy::ToolMap.instance.refresh")[:every]
    assert_equal [1.day, { at: '11:03pm' }],
                 pop_task(minus_237_runners, "Galaxy::ToolMap.instance.refresh")[:every]
  end

  private

  def pop_task(runners, task)
    i = runners.index { |job| job[:task] == task }
    return runners.delete_at(i) if i
    nil
  end
end
