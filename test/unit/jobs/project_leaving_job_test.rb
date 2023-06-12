require 'test_helper'

class PersonLeavingJobTest < ActiveSupport::TestCase
  test 'perform' do
    asset_housekeeper = FactoryBot.create(:asset_housekeeper)
    project = asset_housekeeper.projects.first
    person = FactoryBot.create(:brand_new_person)
    gm = person.group_memberships.create(work_group: asset_housekeeper.work_groups.first)
    data_file = FactoryBot.create(:data_file, projects: [project], contributor: person)
    refute gm.has_left

    assert_equal asset_housekeeper.projects, person.projects

    with_config_value(:auth_lookup_enabled, true) do
      assert_difference('AuthLookupUpdateQueue.count', 2) do # person + housekeeper
        ProjectLeavingJob.new(gm).perform_now
        assert gm.reload.has_left
      end

      assert_equal [person, asset_housekeeper].sort, AuthLookupUpdateQueue.last(2).map(&:item).sort
    end
  end

  test 'queue timed jobs' do
    asset_housekeeper = FactoryBot.create(:asset_housekeeper)
    person1 = FactoryBot.create(:brand_new_person)
    gm1 = person1.group_memberships.create(work_group: asset_housekeeper.work_groups.first, time_left_at: 3.days.ago)
    person2 = FactoryBot.create(:brand_new_person)
    gm2 = person2.group_memberships.create(work_group: asset_housekeeper.work_groups.first, time_left_at: 3.days.ago, has_left: true)
    person3 = FactoryBot.create(:brand_new_person)
    gm3 = person3.group_memberships.create(work_group: asset_housekeeper.work_groups.first, time_left_at: 3.days.from_now)

    assert_enqueued_jobs 1, only: ProjectLeavingJob do
      assert_enqueued_with job: ProjectLeavingJob, args: [gm1] do
        ProjectLeavingJob.queue_timed_jobs
      end
    end
  end
end
