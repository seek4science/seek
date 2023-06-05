require 'test_helper'

class PermissionTest < ActiveSupport::TestCase
  fixtures :all

  setup do
    @programme = FactoryBot.create(:programme)
    @project = FactoryBot.create(:project, programme: @programme)
    @project2 = FactoryBot.create(:project, programme: @programme)
    @institution = FactoryBot.create(:institution)
    @person = FactoryBot.create(:person, project: @project)
    @person.add_to_project_and_institution(@project2, @institution)
    @person2 = FactoryBot.create(:person, project: @project)
    @project2_work_group = @project2.work_groups.first
    @favourite_group = FactoryBot.create(:favourite_group, user: @person.user)
    @favourite_group.favourite_group_memberships.create!(person: @person2, access_type: Policy::MANAGING)

    @data_file = FactoryBot.create(:data_file, projects: [@project], contributor: @person)

    # 1 of each type of permission
    @data_file.policy.permissions.create!(contributor: @institution, access_type: Policy::MANAGING)
    @data_file.policy.permissions.create!(contributor: @programme, access_type: Policy::MANAGING)
    @data_file.policy.permissions.create!(contributor: @project2, access_type: Policy::MANAGING)
    @data_file.policy.permissions.create!(contributor: @project2_work_group, access_type: Policy::MANAGING)
    @data_file.policy.permissions.create!(contributor: @favourite_group, access_type: Policy::MANAGING)
    @data_file.policy.permissions.create!(contributor: @person2, access_type: Policy::MANAGING)
  end

  test 'cleans up project-dependent permissions after delete' do
    assert_difference('Permission.count', -2) do
      @person.group_memberships.last.destroy!
      disable_authorization_checks { @project2.destroy! }
    end

    refute @data_file.policy.reload.permissions.where(contributor_id: @project2, contributor_type: 'Project').any?
    refute @data_file.policy.reload.permissions.where(contributor_id: @project2_work_group, contributor_type: 'WorkGroup').any?
  end

  test 'cleans up institution-dependent permissions after delete' do
    assert_difference('Permission.count', -2) do
      @person.group_memberships.last.destroy!
      disable_authorization_checks { @institution.destroy! }
    end

    refute @data_file.policy.reload.permissions.where(contributor_id: @institution, contributor_type: 'Institution').any?
    refute @data_file.policy.reload.permissions.where(contributor_id: @project2_work_group, contributor_type: 'WorkGroup').any?
  end

  test 'cleans up person-dependent permissions after delete' do
    assert_difference('Permission.count', -1) do
      disable_authorization_checks { @person2.destroy! }
    end

    refute @data_file.policy.reload.permissions.where(contributor_id: @person2, contributor_type: 'Person').any?
  end

  test 'cleans up programme-dependent permissions after delete' do
    assert_difference('Permission.count', -1) do
      disable_authorization_checks { @programme.destroy! }
    end

    refute @data_file.policy.reload.permissions.where(contributor_id: @programme, contributor_type: 'Programme').any?
  end

  test 'cleans up work group-dependent permissions after delete' do
    assert_difference('Permission.count', -1) do
      @person.group_memberships.last.destroy!
      disable_authorization_checks { @project2_work_group.destroy! }
    end

    refute @data_file.policy.reload.permissions.where(contributor_id: @project2_work_group, contributor_type: 'WorkGroup').any?
  end

  test 'cleans up favourite group-dependent permissions after delete' do
    assert_difference('Permission.count', -1) do
      disable_authorization_checks { @favourite_group.destroy! }
    end

    refute @data_file.policy.reload.permissions.where(contributor_id: @favourite_group, contributor_type: 'FavouriteGroup').any?
  end

  test 'contributor_type of permission is validated' do
    disable_authorization_checks do
      assert @data_file.policy.permissions.create(contributor: @programme, access_type: Policy::EDITING)
      assert @data_file.policy.permissions.create(contributor: @project2, access_type: Policy::EDITING)
      assert @data_file.policy.permissions.create(contributor: @institution, access_type: Policy::EDITING)
      assert @data_file.policy.permissions.create(contributor: @person, access_type: Policy::EDITING)
      assert @data_file.policy.permissions.create(contributor: @project2_work_group, access_type: Policy::EDITING)
      assert @data_file.policy.permissions.create(contributor: @favourite_group, access_type: Policy::EDITING)

      p = @data_file.policy.permissions.build(contributor: FactoryBot.create(:sop), access_type: Policy::EDITING)
      refute p.save
      assert p.errors[:contributor_type].any?
    end
  end
end
