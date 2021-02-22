require 'test_helper'

class PolicyBasedAuthTest < ActiveSupport::TestCase
  fixtures :all

  test 'has advanced permissions' do
    user = Factory(:user)
    User.current_user = user
    proj1 = user.person.projects.first
    proj2 = Factory(:project)
    user.person.add_to_project_and_institution(proj2, Factory(:institution))
    person1 = Factory :person
    person2 = Factory :person
    df = Factory :data_file, policy: Factory(:private_policy), contributor: user.person, projects: [proj1]

    assert !df.has_advanced_permissions?
    Factory(:permission, contributor: person1, access_type: Policy::EDITING, policy: df.policy)
    assert df.reload.has_advanced_permissions?

    model = Factory :model, policy: Factory(:public_policy), contributor: user.person, projects: [proj1, proj2]
    assert !model.reload.has_advanced_permissions?
    Factory(:permission, contributor: Factory(:institution), access_type: Policy::ACCESSIBLE, policy: model.policy)
    assert model.reload.has_advanced_permissions?

    # when having a sharing_scope policy of Policy::ALL_USERS it is considered to have advanced permissions if any of the permissions do not relate to the projects associated with the resource (ISA or Asset))
    # this is a temporary work-around for the loss of the custom_permissions flag when defining a pre-canned permission of shared with sysmo, but editable/downloadable within my project
    assay = Factory :experimental_assay, policy: Factory(:all_sysmo_viewable_policy), contributor: user.person,
                                         study: Factory(:study, contributor: user.person,
                                                                investigation: Factory(:investigation, contributor: user.person, projects: [proj1, proj2]))
    assay.policy.permissions << Factory(:permission, contributor: proj1, access_type: Policy::EDITING)
    assay.policy.permissions << Factory(:permission, contributor: proj2, access_type: Policy::EDITING)
    assay.save!
    assert !assay.reload.has_advanced_permissions?
    proj_permission = Factory(:permission, contributor: Factory(:project), access_type: Policy::EDITING)
    assay.policy.permissions << proj_permission
    assert assay.reload.has_advanced_permissions?
    assay.policy.permissions.delete(proj_permission)
    assay.save!
    assert !assay.reload.has_advanced_permissions?
    assay.policy.permissions << Factory(:permission, contributor: Factory(:project), access_type: Policy::VISIBLE)
    assert assay.reload.has_advanced_permissions?
  end

  test 'people within the same project can_see_hidden_item' do
    test_user = Factory(:user)
    person = Factory(:person, project: test_user.person.projects.first)
    datafile = Factory(:data_file, projects: person.projects, policy: Factory(:private_policy), contributor: person)
    refute datafile.can_view?(test_user)
    assert datafile.can_see_hidden_item? test_user.person
  end

  test 'people in different project can_not_see_hidden_item' do
    test_user = Factory(:user)
    datafile = Factory(:data_file, policy: Factory(:private_policy))
    refute datafile.can_view?(test_user)
    refute datafile.can_see_hidden_item?(test_user.person)
  end

  test 'authorization_permissions' do
    [true, false].each do |lookup_enabled|
      with_config_value :auth_lookup_enabled, lookup_enabled do
        Sop.delete_all
        user = Factory(:person).user
        other_user = Factory :user
        sop = Factory :sop, contributor: user.person, policy: Factory(:editing_public_policy)
        Sop.clear_lookup_table

        sop.update_lookup_table(user) if lookup_enabled
        sop.update_lookup_table(other_user) if lookup_enabled

        permissions = sop.authorization_permissions user
        assert permissions.can_view
        assert permissions.can_download
        assert permissions.can_edit
        assert permissions.can_manage
        assert permissions.can_delete

        permissions = sop.authorization_permissions other_user
        assert permissions.can_view
        assert permissions.can_download
        assert permissions.can_edit
        refute permissions.can_manage
        refute permissions.can_delete

        Investigation.delete_all
        user = Factory(:person).user
        other_user = Factory :user
        study = Factory(:study, contributor: user.person, policy: Factory(:editing_public_policy))
        inv = study.investigation
        Investigation.clear_lookup_table

        inv.update_lookup_table(user) if lookup_enabled
        inv.update_lookup_table(other_user) if lookup_enabled

        permissions = inv.authorization_permissions user
        assert permissions.can_view
        assert permissions.can_download
        assert permissions.can_edit
        assert permissions.can_manage
        refute permissions.can_delete, 'State should not allow delete, because investigation has studies'

        permissions = inv.authorization_permissions other_user
        assert permissions.can_view
        assert permissions.can_download
        assert permissions.can_edit
        refute permissions.can_manage
        refute permissions.can_delete
      end
    end
  end

  test 'update lookup table' do
    with_config_value :auth_lookup_enabled, true do
      user = Factory :user
      other_user = Factory :user
      sop = Factory :sop, contributor: user.person, policy: Factory(:editing_public_policy)
      Sop.clear_lookup_table
      # check using the standard
      assert sop.authorized_for_view?(user)
      assert sop.authorized_for_download?(user)
      assert sop.authorized_for_edit?(user)
      assert sop.authorized_for_manage?(user)
      assert sop.authorized_for_delete?(user)

      assert sop.authorized_for_view?(other_user)
      assert sop.authorized_for_download?(other_user)
      assert sop.authorized_for_edit?(other_user)
      refute sop.authorized_for_manage?(other_user)
      refute sop.authorized_for_delete?(other_user)

      sop.update_lookup_table(user)
      sop.update_lookup_table(other_user)

      assert sop.can_view?(user)
      assert sop.can_download?(user)
      assert sop.can_edit?(user)
      assert sop.can_manage?(user)
      assert sop.can_delete?(user)

      assert sop.can_view?(other_user)
      assert sop.can_download?(other_user)
      assert sop.can_edit?(other_user)
      refute sop.can_manage?(other_user)
      refute sop.can_delete?(other_user)

      # directly check the lookup table
      assert sop.lookup_for('view', user.id)
      assert sop.lookup_for('download', user.id)
      assert sop.lookup_for('edit', user.id)
      assert sop.lookup_for('manage', user.id)
      assert sop.lookup_for('delete', user.id)

      assert sop.lookup_for('view', other_user.id)
      assert sop.lookup_for('download', other_user.id)
      assert sop.lookup_for('edit', other_user.id)
      refute sop.lookup_for('manage', other_user.id)
      refute sop.lookup_for('delete', other_user.id)

      # change permissions
      sop.policy = Factory(:private_policy)
      disable_authorization_checks do
        sop.save!
      end

      sop.update_lookup_table(user)
      sop.update_lookup_table(other_user)

      assert sop.can_view?(user)
      assert sop.can_download?(user)
      assert sop.can_edit?(user)
      assert sop.can_manage?(user)
      assert sop.can_delete?(user)

      refute sop.can_view?(other_user)
      refute sop.can_download?(other_user)
      refute sop.can_edit?(other_user)
      refute sop.can_manage?(other_user)
      refute sop.can_delete?(other_user)

      # directly check the lookup table
      assert sop.lookup_for('view', user.id)
      assert sop.lookup_for('download', user.id)
      assert sop.lookup_for('edit', user.id)
      assert sop.lookup_for('manage', user.id)
      assert sop.lookup_for('delete', user.id)

      refute sop.lookup_for('view', other_user.id)
      refute sop.lookup_for('download', other_user.id)
      refute sop.lookup_for('edit', other_user.id)
      refute sop.lookup_for('manage', other_user.id)
      refute sop.lookup_for('delete', other_user.id)
    end
  end

  test 'lookup table counts' do
    with_config_value :auth_lookup_enabled, true do
      User.current_user = nil
      user = Factory :user
      disable_authorization_checks do
        Sop.clear_lookup_table
        assert_equal 0, Sop.lookup_count_for_user(user.id)
        sop = Factory :sop
        assert_equal 0, Sop.lookup_count_for_user(user.id)
        sop.update_lookup_table(user)
        assert_equal 1, Sop.lookup_count_for_user(user.id)
        assert sop.destroy
        assert_equal 0, Sop.lookup_count_for_user(user.id)
      end
    end
  end

  test 'remove_invalid_auth_lookup_entries' do
    with_config_value :auth_lookup_enabled, true do
      User.current_user = nil
      user = Factory :user
      disable_authorization_checks do
        Sop.clear_lookup_table
        sop = Factory :sop
        sop.update_lookup_table(user)
        assert_equal 1, Sop.lookup_count_for_user(user.id)
        assert_equal 2, Sop.connection.select_one('select count(*) from sop_auth_lookup;').values[0].to_i
        f = ActiveRecord::Base.connection.quote(false)
        Sop.connection.execute("insert into sop_auth_lookup(user_id,asset_id,can_view,can_manage,can_edit,can_download,can_delete) values (#{user.id},#{sop.id + 10},#{f},#{f},#{f},#{f},#{f});")
        Sop.connection.execute("insert into sop_auth_lookup(user_id,asset_id,can_view,can_manage,can_edit,can_download,can_delete) values (#{user.id},#{sop.id + 11},#{f},#{f},#{f},#{f},#{f});")
        Sop.connection.execute("insert into sop_auth_lookup(user_id,asset_id,can_view,can_manage,can_edit,can_download,can_delete) values (0,#{sop.id + 10},#{f},#{f},#{f},#{f},#{f});")
        assert_equal 3, Sop.lookup_count_for_user(user.id)
        assert_equal 5, Sop.connection.select_one('select count(*) from sop_auth_lookup;').values[0].to_i
        Sop.remove_invalid_auth_lookup_entries
        assert_equal 1, Sop.lookup_count_for_user(user.id)
        assert_equal 2, Sop.connection.select_one('select count(*) from sop_auth_lookup;').values[0].to_i
      end
    end
  end

  test 'people flagged as having left a project cannot see project-shared items' do
    person = Factory(:former_project_person)
    project = person.projects.first
    active_person = Factory(:person, project: project)

    assert person.current_projects.empty?
    assert_includes person.former_projects, project
    assert_includes active_person.current_projects, project
    assert_includes project.former_people, person
    assert_includes project.current_people, active_person

    data = Factory(:data_file, policy: Factory(:private_policy,
                                               permissions: [Factory(:edit_permission, contributor: project)]))

    assert data.can_view?(active_person)
    assert data.can_edit?(active_person)
    refute data.can_view?(person)
    refute data.can_edit?(person)
  end

  test 'people flagged as leaving a project in the future can still see project-shared items' do
    person = Factory(:future_former_project_person)
    project = person.projects.first
    active_person = Factory(:person, project: project)

    assert_includes person.current_projects, project
    assert_empty person.former_projects
    assert_includes active_person.current_projects, project
    assert_includes project.current_people, person
    assert_includes project.current_people, active_person

    data = Factory(:data_file, policy: Factory(:private_policy,
                                               permissions: [Factory(:edit_permission, contributor: project)]))

    assert data.can_view?(active_person)
    assert data.can_edit?(active_person)
    assert data.can_view?(person)
    assert data.can_edit?(person)
  end
end