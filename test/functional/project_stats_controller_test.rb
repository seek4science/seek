require 'test_helper'


class ProjectStatsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  test 'clear cache' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    login_as(person)
    key = "Project_#{project.id}_dashboard_stats_activity"
    refute Rails.cache.exist?(key)
    Rails.cache.fetch(key) { 'fish' }
    assert Rails.cache.exist?(key)

    request.env["HTTP_REFERER"] = dashboard_project_stats_path(project)

    post :clear_cache, params: { project_id:project.id }
    assert_redirected_to dashboard_project_stats_path(project)

    refute Rails.cache.exist?(key)

  end

  test 'none project member cannot clear cache' do
    person = FactoryBot.create(:person)
    project = FactoryBot.create(:project)
    login_as(person)
    key = "Project_#{project.id}_dashboard_stats_activity"
    refute Rails.cache.exist?(key)
    Rails.cache.fetch(key) { 'fish' }
    assert Rails.cache.exist?(key)

    request.env["HTTP_REFERER"] = dashboard_project_stats_path(project)

    post :clear_cache, params: { project_id:project.id }
    assert_redirected_to project_path(project)

    assert Rails.cache.exist?(key)
  end

  test 'project member can get stats' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    login_as(person)

    get :contributors, params: { project_id: project.id, start_date: '2015-10-10', end_date: '2015-10-11', format: :json }

    assert_response :success
  end

  test 'non-project member cannot get stats' do
    person = FactoryBot.create(:person)
    project = FactoryBot.create(:project)
    login_as(person)

    get :contributors, params: { project_id: project.id, start_date: '2015-10-10', end_date: '2015-10-11', format: :json }

    assert_redirected_to project_path(project)
    assert flash[:error].include?('not a member')
  end
end
