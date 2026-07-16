require 'test_helper'

class ApplicationStatusTest < ActiveSupport::TestCase

  def setup
    ApplicationStatus.delete_all
  end

  test 'validation' do
    app = ApplicationStatus.new(running_jobs:5)
    assert app.valid?

    app = ApplicationStatus.new(running_jobs:5)
    assert app.valid?

    app = ApplicationStatus.new(running_jobs:nil)
    refute app.valid?
  end

  test 'instance' do
    app = nil
    assert_difference('ApplicationStatus.count') do
      app = ApplicationStatus.instance
      assert app.valid?
    end
    assert_no_difference('ApplicationStatus.count') do
      assert_equal app, ApplicationStatus.instance
    end
  end

  test 'refresh' do
    app = ApplicationStatus.instance
    app.refresh
    app.reload
    alive_since = SolidQueue.process_alive_threshold.ago
    expected = SolidQueue::Process.where(kind: 'Worker').where('last_heartbeat_at > ?', alive_since).count
    assert_equal expected, app.running_jobs
    assert_equal Seek::Config.solr_enabled, app.search_enabled
  end

  test 'refresh only counts workers, not other solid queue process kinds' do
    common = { hostname: 'test', last_heartbeat_at: Time.current, supervisor_id: nil, metadata: {} }
    SolidQueue::Process.create!(**common, kind: 'Worker', name: 'worker-1', pid: 1)
    SolidQueue::Process.create!(**common, kind: 'Dispatcher', name: 'dispatcher-1', pid: 2)
    SolidQueue::Process.create!(**common, kind: 'Supervisor', name: 'supervisor-1', pid: 3)

    app = ApplicationStatus.instance
    app.refresh
    app.reload
    assert_equal 1, app.running_jobs
  end

  test 'search_enabled' do
    with_config_value(:solr_enabled, true) do
      assert ApplicationStatus.instance.search_enabled
    end
    with_config_value(:solr_enabled, false) do
      refute ApplicationStatus.instance.search_enabled
    end
  end

  test 'validate_singleton' do
    app = ApplicationStatus.instance
    assert_raise RuntimeError do
      ApplicationStatus.create(running_jobs:5)
    end
  end

end