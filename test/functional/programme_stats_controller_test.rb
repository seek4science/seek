require 'test_helper'

class ProgrammeStatsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  test 'clear cache' do
    person = FactoryBot.create(:programme_administrator)
    programme = person.administered_programmes.first
    login_as(person)
    key = "Programme_#{programme.id}_dashboard_stats_activity"
    refute Rails.cache.exist?(key)
    Rails.cache.fetch(key) { 'fish' }
    assert Rails.cache.exist?(key)

    request.env["HTTP_REFERER"] = dashboard_programme_stats_path(programme)

    post :clear_cache, params: { programme_id:programme.id }
    assert_redirected_to dashboard_programme_stats_path(programme)

    refute Rails.cache.exist?(key)

  end

  test 'regular programme member cannot clear cache' do
    programme = FactoryBot.create(:programme)
    person = FactoryBot.create(:person, project: programme.projects.first)

    login_as(person)
    key = "Programme_#{programme.id}_dashboard_stats_activity"
    refute Rails.cache.exist?(key)
    Rails.cache.fetch(key) { 'fish' }
    assert Rails.cache.exist?(key)

    request.env["HTTP_REFERER"] = dashboard_programme_stats_path(programme)

    post :clear_cache, params: { programme_id:programme.id }
    assert_redirected_to programme_path(programme)

    assert Rails.cache.exist?(key)
  end

  test 'non-programme member cannot clear cache' do
    person = FactoryBot.create(:person)
    programme = FactoryBot.create(:programme)
    login_as(person)
    key = "Programme_#{programme.id}_dashboard_stats_activity"
    refute Rails.cache.exist?(key)
    Rails.cache.fetch(key) { 'fish' }
    assert Rails.cache.exist?(key)

    request.env["HTTP_REFERER"] = dashboard_programme_stats_path(programme)

    post :clear_cache, params: { programme_id:programme.id }
    assert_redirected_to programme_path(programme)

    assert Rails.cache.exist?(key)
  end

end