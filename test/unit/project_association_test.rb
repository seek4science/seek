require 'test_helper'

class ProjectAssociationTest < ActiveSupport::TestCase

  test 'programmes distinct' do
    projects = [FactoryBot.create(:project),FactoryBot.create(:project)]
    programme = FactoryBot.create(:programme,projects:projects)
    event = FactoryBot.create(:event, projects:projects, policy:FactoryBot.create(:public_policy))
    assert_equal projects.sort, event.projects.sort
    assert_equal [programme],event.programmes

    # ISA association with programmes is handled through acts_as_isa, but including in the test here as the problem is
    # the same and they should be consolidated in the future
    investigation = FactoryBot.create(:investigation, projects:projects, policy:FactoryBot.create(:public_policy))
    assert_equal projects.sort, investigation.projects.sort
    assert_equal [programme],investigation.programmes

    study = FactoryBot.create(:study, investigation: investigation)
    assert_equal projects.sort, study.projects.sort
    assert_equal [programme],study.programmes
  end

end