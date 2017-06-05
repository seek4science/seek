require 'test_helper'

class PersonLeavingJobTest < ActiveSupport::TestCase

  test 'perform' do
    asset_housekeeper = Factory(:asset_housekeeper)
    project = asset_housekeeper.projects.first
    person = Factory(:brand_new_person)
    person.group_memberships.create(work_group: asset_housekeeper.work_groups.first)
    data_file = Factory(:data_file, projects: [project], contributor: person)

    assert_equal asset_housekeeper.projects, person.projects

    with_config_value(:auth_lookup_enabled, true) do
      assert_difference('AuthLookupUpdateQueue.count', 2) do # person + housekeeper
        ProjectLeavingJob.new(person, project).perform
      end

      assert_equal [person, asset_housekeeper].sort, AuthLookupUpdateQueue.last(2).map(&:item).sort
    end
  end

end

