require 'test_helper'
require 'minitest/mock'

class SettingsPropagationTest < ActionDispatch::IntegrationTest

  setup do
    Seek::Config.settings_cache
    Seek::Config.site_base_host = 'http://website.golf' # Make sure at least 1 Setting exists
    # Modify settings table without triggering cache clearance
    Settings.last.update_column(:updated_at, 5.minutes.from_now)
    RequestStore.delete(:config_cache)
  end

  test 'propagation triggered on request if settings were changed' do
    assert Seek::Config.settings_changed?
    propagation_happened = false
    Seek::Config.stub(:propagate_all, -> () { propagation_happened = true }) do
      refute propagation_happened
      get root_path
      assert propagation_happened
      refute Seek::Config.settings_changed?
    end
  end

  test 'propagation triggered before performing job if settings were changed' do
    do_nothing_job = Class.new(ApplicationJob) do
      def perform
        # no op
      end
    end

    assert Seek::Config.settings_changed?
    propagation_happened = false
    Seek::Config.stub(:propagate_all, -> () { propagation_happened = true }) do
      refute propagation_happened
      do_nothing_job.new.perform_now
      assert propagation_happened
      refute Seek::Config.settings_changed?
    end
  end
end