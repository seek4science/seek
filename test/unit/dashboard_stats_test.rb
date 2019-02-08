require 'test_helper'

class DashboardStatsTest < ActiveSupport::TestCase
  test 'clear cache' do
    suffixes = %w[activity contributions all_asset_accessibility contributor_activity]
    # admin
    base = 'admin_dashboard_stats'
    suffixes.each do |suffix|
      key = "#{base}_#{suffix}"
      refute Rails.cache.exist?(key)
      Rails.cache.fetch(key) { 'fish' }
      assert Rails.cache.exist?(key)
    end

    db = Seek::Stats::DashboardStats.new
    db.clear_caches

    suffixes.each do |suffix|
      key = "#{base}_#{suffix}"
      refute Rails.cache.exist?(key)
    end

    # project scope
    proj = Factory(:project)

    base = "Project_#{proj.id}_dashboard_stats"
    suffixes.each do |suffix|
      key = "#{base}_#{suffix}"
      refute Rails.cache.exist?(key)
      Rails.cache.fetch(key) { 'fish' }
      assert Rails.cache.exist?(key)
    end

    # check another project isn't cleared
    another_project_key = "Project_#{proj.id + 1}_dashboard_stats"
    refute Rails.cache.exist?(another_project_key)
    Rails.cache.fetch(another_project_key) { 'fish' }
    assert Rails.cache.exist?(another_project_key)

    db = Seek::Stats::DashboardStats.new(proj)
    db.clear_caches

    suffixes.each do |suffix|
      key = "#{base}_#{suffix}"
      refute Rails.cache.exist?(key)
    end

    assert Rails.cache.exist?(another_project_key)
  end

  test 'scope type guard' do

    #happy if nil
    Seek::Stats::DashboardStats.new
    Seek::Stats::DashboardStats.new(nil)

    #happy if project
    Seek::Stats::DashboardStats.new(Factory(:project))

    #not happy if something else
    assert_raise Seek::Stats::DashboardStats::InvalidScopeException do
      Seek::Stats::DashboardStats.new("I am a string")
    end
    assert_raise Seek::Stats::DashboardStats::InvalidScopeException do
      Seek::Stats::DashboardStats.new(Factory(:person))
    end

  end
end
