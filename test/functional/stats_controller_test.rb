require 'test_helper'


class StatsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  test 'clear cache' do
    person = FactoryBot.create(:admin)
    login_as(person)
    key = "admin_dashboard_stats_activity"
    refute Rails.cache.exist?(key)
    Rails.cache.fetch(key) { 'fish' }
    assert Rails.cache.exist?(key)

    request.env["HTTP_REFERER"] = dashboard_admin_stats_path

    post :clear_cache
    assert_redirected_to dashboard_admin_stats_path

    refute Rails.cache.exist?(key)

  end

  test 'none admins cannot clear cache' do
    person = FactoryBot.create(:person)
    login_as(person)
    key = "admin_dashboard_stats_activity"
    refute Rails.cache.exist?(key)
    Rails.cache.fetch(key) { 'fish' }
    assert Rails.cache.exist?(key)

    request.env["HTTP_REFERER"] = dashboard_admin_stats_path

    post :clear_cache
    assert_redirected_to :root

    assert Rails.cache.exist?(key)

  end

end