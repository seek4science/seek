require 'test_helper'

class RecurringTest < ActiveSupport::TestCase
  setup do
    @config = ActiveSupport::ConfigurationFile.parse(Rails.root.join('config/recurring.yml')).deep_symbolize_keys
    @tasks = @config[:production].deep_dup
  end

  test 'should read recurring schedule file' do
    daily = pop_task(:periodic_subscription_email_daily)
    assert_equal 'PeriodicSubscriptionEmailJob', daily[:class]
    assert_equal ['daily'], daily[:args]
    assert_equal '0 0 * * *', daily[:schedule]

    weekly = pop_task(:periodic_subscription_email_weekly)
    assert_equal 'PeriodicSubscriptionEmailJob', weekly[:class]
    assert_equal ['weekly'], weekly[:args]
    assert_equal '0 0 1,8,15,22 * *', weekly[:schedule]

    monthly = pop_task(:periodic_subscription_email_monthly)
    assert_equal 'PeriodicSubscriptionEmailJob', monthly[:class]
    assert_equal ['monthly'], monthly[:args]
    assert_equal '0 0 1 * *', monthly[:schedule]

    regular = pop_task(:regular_maintenance)
    assert_equal 'RegularMaintenanceJob', regular[:class]
    assert_equal '0 */4 * * *', regular[:schedule]

    auth = pop_task(:auth_lookup_maintenance)
    assert_equal 'AuthLookupMaintenanceJob', auth[:class]
    assert_equal '0 */8 * * *', auth[:schedule]

    life_monitor = pop_task(:life_monitor_status)
    assert_equal 'LifeMonitorStatusJob', life_monitor[:class]
    assert_equal '0 2 * * *', life_monitor[:schedule]

    news_refresh = pop_task(:news_feed_refresh)
    assert_equal 'NewsFeedRefreshJob', news_refresh[:class]
    assert_equal 3, news_refresh[:priority]
    assert_equal "*/#{Seek::Config.home_feeds_cache_timeout} * * * *", news_refresh[:schedule]

    queue_timed = pop_task(:queue_timed_jobs)
    assert_equal 'ApplicationJob.queue_timed_jobs', queue_timed[:command]
    assert_equal '*/10 * * * *', queue_timed[:schedule]

    clear_finished = pop_task(:clear_finished_jobs)
    assert_equal 'SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)', clear_finished[:command]
    assert_equal '12 * * * *', Fugit.parse(clear_finished[:schedule].to_s).to_cron_s

    app_status = pop_task(:application_status_refresh)
    assert_equal 'ApplicationStatus.instance.refresh', app_status[:command]
    assert_equal '* * * * *', app_status[:schedule]

    tool_map_refresh = pop_task(:galaxy_tool_map_refresh)
    assert_equal 'Galaxy::ToolMap.instance.refresh', tool_map_refresh[:command]
    assert_equal '0 3 * * *', tool_map_refresh[:schedule]

    data_dump = pop_task(:bioschema_data_dump_generate)
    assert_equal 'Seek::BioSchema::DataDump.generate_dumps', data_dump[:command]
    assert_equal '10 0 * * *', data_dump[:schedule]

    assert_empty @tasks, "Found untested recurring task(s): #{@tasks.keys.join(', ')}"
  end

  test 'should offset daily job runtime by configured amount' do
    with_config_value(:regular_job_offset, 43) do
      positive_offset = production_tasks
      assert_equal '43 0 * * *', positive_offset[:periodic_subscription_email_daily][:schedule]
      assert_equal '43 2 * * *', positive_offset[:life_monitor_status][:schedule]
      assert_equal '43 3 * * *', positive_offset[:galaxy_tool_map_refresh][:schedule]
      # hour-frequency jobs don't get the offset applied - matches whenever's quirk (see comment in recurring.yml)
      assert_equal '0 */4 * * *', positive_offset[:regular_maintenance][:schedule]
    end

    with_config_value(:regular_job_offset, -237) do
      negative_offset = production_tasks
      assert_equal '3 20 * * *', negative_offset[:periodic_subscription_email_daily][:schedule]
      assert_equal '3 22 * * *', negative_offset[:life_monitor_status][:schedule]
      assert_equal '3 23 * * *', negative_offset[:galaxy_tool_map_refresh][:schedule]
    end
  end

  test 'news feed refresh schedule changes with config' do
    with_config_value(:home_feeds_cache_timeout, 731) do
      assert_equal '*/731 * * * *', production_tasks[:news_feed_refresh][:schedule]
    end
  end

  test 'schedules are all valid cron expressions' do
    @tasks.each do |key, options|
      assert Fugit.parse(options[:schedule].to_s),
             "#{key}: #{options[:schedule].inspect} did not parse as a valid schedule"
    end
  end

  test 'each task resolves to a valid recurring task, with a queue that has a configured worker' do
    # Recurring tasks aren't feature-flag gated, but some of the queues they target are
    # (config/queue.yml only starts a worker for e.g. `authlookup` when auth_lookup_enabled is
    # on) - so this needs every optional feature enabled to see the full set of queues a fully
    # configured instance would have workers for.
    all_features_enabled = {
      auth_lookup_enabled: true, cache_remote_files: true, samples_enabled: true,
      solr_enabled: true, isa_json_compliance_enabled: true, data_files_enabled: true
    }
    with_config_values(all_features_enabled) do
      queue_config = ActiveSupport::ConfigurationFile.parse(Rails.root.join('config/queue.yml')).deep_symbolize_keys
      configured_queues = queue_config[:production][:workers].map { |w| w[:queues] }

      @tasks.each do |key, options|
        task = SolidQueue::RecurringTask.from_configuration(key.to_s, **options)
        assert task.valid?, "#{key}: #{task.errors.full_messages.join(', ')}"

        # class: entries use that job class's own queue_as; command:-only entries fall back to
        # SolidQueue::RecurringJob's queue_as (:solid_queue_recurring) - both need a worker
        # configured in config/queue.yml, or the task enqueues but is never picked up (see
        # SOLID_QUEUE_MIGRATION_PLAN.md for the bug this test guards against).
        job_class = options[:class]&.safe_constantize || SolidQueue::RecurringJob
        assert_includes configured_queues, job_class.queue_name,
                        "#{key} enqueues onto '#{job_class.queue_name}', which has no worker in config/queue.yml"
      end
    end
  end

  test 'executes recurring tasks without error' do
    with_config_value(:email_enabled, true) do
      with_config_value(:openbis_enabled, true) do
        VCR.use_cassette('galaxy/fetch_tools_trimmed') do
          VCR.use_cassette('bio_tools/fetch_galaxy_tool_names') do
            perform_enqueued_jobs do
              assert_nothing_raised do
                @tasks.each do |key, options|
                  SolidQueue::RecurringTask.from_configuration(key.to_s, **options).enqueue(at: Time.current)
                end
              end
            end
          end
        end
      end
    end
  end

  private

  def production_tasks
    ActiveSupport::ConfigurationFile.parse(Rails.root.join('config/recurring.yml')).deep_symbolize_keys[:production]
  end

  def pop_task(key)
    @tasks.delete(key)
  end
end
