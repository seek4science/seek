require 'test_helper'

class AdminDefinedRoleProjectTest < ActiveSupport::TestCase
  def setup
    Delayed::Job.delete_all
  end

  test 'fire update auth table job on create' do
    person = Factory(:person)
    with_config_value :auth_lookup_enabled, true do
      assert_difference('Delayed::Job.count', 1) do
        AdminDefinedRoleProject.create person: person, project: person.projects.first, role_mask: 2
      end
    end
  end

  test 'fire update auth table job on destroy' do
    person = Factory(:person)
    role = AdminDefinedRoleProject.create person: person, project: person.projects.first, role_mask: 2
    with_config_value :auth_lookup_enabled, true do
      assert_difference('Delayed::Job.count', 1) do
        role.destroy
      end
    end
  end

  test 'validate mask must be > 0' do
    person = Factory(:person)
    role = AdminDefinedRoleProject.create project: person.projects.first, person: person, role_mask: 0
    assert !role.valid?
    role.role_mask = 2
    assert role.valid?
  end

  test 'validate mask must be <= 16' do
    person = Factory(:person)
    role = AdminDefinedRoleProject.create project: person.projects.first, person: person, role_mask: 17
    assert !role.valid?
    role.role_mask = 16
    assert role.valid?
  end

  test 'validate person must exist' do
    person = Factory(:person)
    role = AdminDefinedRoleProject.create project: person.projects.first, role_mask: 2
    assert !role.valid?
    role.person = person
    assert role.valid?
  end

  test 'validate project must exist' do
    person = Factory(:person)
    role = AdminDefinedRoleProject.create person: person, role_mask: 2
    assert !role.valid?
    role.project = person.projects.first
    assert role.valid?
  end

  test 'validate project must belong to person' do
    person = Factory(:person)
    project = Factory(:project)
    role = AdminDefinedRoleProject.create person: person, project: project, role_mask: 2
    assert !role.valid?
    role.project = person.projects.first
    role.save!
  end
end
