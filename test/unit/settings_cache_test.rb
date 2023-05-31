require 'test_helper'
require 'minitest/mock'

class SettingsCacheTest < ActiveSupport::TestCase
  class TestCacheExpiryException < StandardError; end # Dummy exception raised via a stub so we can check cache expiry

  test 'adding a setting expires the settings cache' do
    Seek::Config.stub(:clear_cache, -> () { raise TestCacheExpiryException }) do
      assert_difference('Settings.count', 1) do
        assert_raises(TestCacheExpiryException) do
          Seek::Config.data_files_enabled = true
        end
      end
    end
  end

  test 'changing a setting expires the settings cache' do
    Seek::Config.data_files_enabled = false
    Seek::Config.stub(:clear_cache, -> () { raise TestCacheExpiryException }) do
      assert_no_difference('Settings.count') do
        assert_raises(TestCacheExpiryException) do
          Seek::Config.data_files_enabled = true
        end
      end
    end
  end

  test 'removing a setting expires the settings cache' do
    Seek::Config.stub(:clear_cache, -> () { raise TestCacheExpiryException }) do
      assert_difference('Settings.count', -1) do
        assert_raises(TestCacheExpiryException) do
          Settings.global.last.destroy!
        end
      end
    end
  end

  test 'setting project settings does not expire settings cache' do
    project = FactoryBot.create(:project)

    Seek::Config.stub(:clear_cache, -> () { raise 'oh no!' }) do
      assert_nothing_raised do
        assert_difference('Settings.count', 1) do
          project.settings['nels_enabled'] = true
        end
      end
    end
  end
end