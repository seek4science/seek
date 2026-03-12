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
    proj = FactoryBot.create(:project)

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

    db = Seek::Stats::ProjectDashboardStats.new(proj)
    db.clear_caches

    suffixes.each do |suffix|
      key = "#{base}_#{suffix}"
      refute Rails.cache.exist?(key)
    end

    assert Rails.cache.exist?(another_project_key)
  end

  test 'contribution stats' do
    travel_to(Time.zone.local(2024, 9, 15, 12, 0, 0)) do
      Project.delete_all
      Programme.delete_all

      programme = FactoryBot.create(:min_programme)
      project = FactoryBot.create(:project, programme: programme)
      person = FactoryBot.create(:person, project: project)

      assets = [:data_file, :sop, :model, :publication, :presentation, :document, :workflow, :collection].map do |type|
        type.to_s.classify.constantize.delete_all
        FactoryBot.create(type, projects: [project], contributor: person)
      end

      Investigation.delete_all
      investigation = FactoryBot.create(:investigation, projects: [project], contributor: person)
      Study.delete_all
      study = FactoryBot.create(:study, investigation: investigation, contributor: person)
      Assay.delete_all
      assay = FactoryBot.create(:assay, study: study, contributor: person)
      ObservationUnit.delete_all
      obs_unit = FactoryBot.create(:observation_unit, study: study, contributor: person)

      instance_stats = Seek::Stats::DashboardStats.new
      # Reload to refresh associations
      project_stats = Seek::Stats::ProjectDashboardStats.new(project.reload)
      programme_stats = Seek::Stats::ProgrammeDashboardStats.new(programme.reload)

      opts = [2.days.ago, 2.days.from_now, 'month']
      types = [DataFile, Sop, Model, Publication, Presentation, Document, Workflow, Collection, Investigation, Study, Assay, ObservationUnit]

      c = instance_stats.contributions(*opts)
      (types + [Project, Programme]).each do |t|
        assert c[:datasets].key?(t), "#{t.name} missing from instance contributions stats"
        assert_equal [1], c[:datasets][t], "#{t.name} unexpected number in instance contributions stats"
      end

      c = programme_stats.contributions(*opts)
      (types + [Project]).each do |t|
        assert c[:datasets].key?(t), "#{t.name} missing from programme contributions stats"
        assert_equal [1], c[:datasets][t], "#{t.name} unexpected number in programme contributions stats"
      end

      c = project_stats.contributions(*opts)
      types.each do |t|
        assert c[:datasets].key?(t), "#{t.name} missing from project contributions stats"
        assert_equal [1], c[:datasets][t], "#{t.name} unexpected number in project contributions stats"
      end
    end
  end
end
