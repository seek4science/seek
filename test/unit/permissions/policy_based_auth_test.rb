require 'test_helper'

class PolicyBasedAuthTest < ActiveSupport::TestCase
  fixtures :all

  test 'has advanced permissions' do
    user = FactoryBot.create(:user)
    User.current_user = user
    proj1 = user.person.projects.first
    proj2 = FactoryBot.create(:project)
    user.person.add_to_project_and_institution(proj2, FactoryBot.create(:institution))
    person1 = FactoryBot.create :person
    person2 = FactoryBot.create :person
    df = FactoryBot.create :data_file, policy: FactoryBot.create(:private_policy), contributor: user.person, projects: [proj1]

    assert !df.has_advanced_permissions?
    FactoryBot.create(:permission, contributor: person1, access_type: Policy::EDITING, policy: df.policy)
    assert df.reload.has_advanced_permissions?

    model = FactoryBot.create :model, policy: FactoryBot.create(:public_policy), contributor: user.person, projects: [proj1, proj2]
    assert !model.reload.has_advanced_permissions?
    FactoryBot.create(:permission, contributor: FactoryBot.create(:institution), access_type: Policy::ACCESSIBLE, policy: model.policy)
    assert model.reload.has_advanced_permissions?

    # when having a sharing_scope policy of Policy::ALL_USERS it is considered to have advanced permissions if any of the permissions do not relate to the projects associated with the resource (ISA or Asset))
    # this is a temporary work-around for the loss of the custom_permissions flag when defining a pre-canned permission of shared with sysmo, but editable/downloadable within my project
    assay = FactoryBot.create :experimental_assay, policy: FactoryBot.create(:all_sysmo_viewable_policy), contributor: user.person,
                                         study: FactoryBot.create(:study, contributor: user.person,
                                                                investigation: FactoryBot.create(:investigation, contributor: user.person, projects: [proj1, proj2]))
    assay.policy.permissions << FactoryBot.create(:permission, contributor: proj1, access_type: Policy::EDITING)
    assay.policy.permissions << FactoryBot.create(:permission, contributor: proj2, access_type: Policy::EDITING)
    assay.save!
    assert !assay.reload.has_advanced_permissions?
    proj_permission = FactoryBot.create(:permission, contributor: FactoryBot.create(:project), access_type: Policy::EDITING)
    assay.policy.permissions << proj_permission
    assert assay.reload.has_advanced_permissions?
    assay.policy.permissions.delete(proj_permission)
    assay.save!
    assert !assay.reload.has_advanced_permissions?
    assay.policy.permissions << FactoryBot.create(:permission, contributor: FactoryBot.create(:project), access_type: Policy::VISIBLE)
    assert assay.reload.has_advanced_permissions?
  end

  test 'people within the same project can_see_hidden_item' do
    test_user = FactoryBot.create(:user)
    person = FactoryBot.create(:person, project: test_user.person.projects.first)
    datafile = FactoryBot.create(:data_file, projects: person.projects, policy: FactoryBot.create(:private_policy), contributor: person)
    refute datafile.can_view?(test_user)
    assert datafile.can_see_hidden_item? test_user.person
  end

  test 'people in different project can_not_see_hidden_item' do
    test_user = FactoryBot.create(:user)
    datafile = FactoryBot.create(:data_file, policy: FactoryBot.create(:private_policy))
    refute datafile.can_view?(test_user)
    refute datafile.can_see_hidden_item?(test_user.person)
  end

  test 'authorization_permissions' do
    [true, false].each do |lookup_enabled|
      with_config_value :auth_lookup_enabled, lookup_enabled do
        Sop.delete_all
        user = FactoryBot.create(:person).user
        other_user = FactoryBot.create :user
        sop = FactoryBot.create :sop, contributor: user.person, policy: FactoryBot.create(:editing_public_policy)
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
        user = FactoryBot.create(:person).user
        other_user = FactoryBot.create :user
        study = FactoryBot.create(:study, contributor: user.person, policy: FactoryBot.create(:editing_public_policy))
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
      user = FactoryBot.create :user
      other_user = FactoryBot.create :user
      sop = FactoryBot.create :sop, contributor: user.person, policy: FactoryBot.create(:editing_public_policy)
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
      sop.policy = FactoryBot.create(:private_policy)
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
      user = FactoryBot.create :user
      disable_authorization_checks do
        Sop.clear_lookup_table
        assert_equal 0, Sop.lookup_count_for_user(user.id)
        sop = FactoryBot.create :sop
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
      user = FactoryBot.create :user
      disable_authorization_checks do
        Sop.clear_lookup_table
        sop = FactoryBot.create :sop
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

        # and remove duplicates
        Sop.connection.execute("insert into sop_auth_lookup(user_id,asset_id,can_view,can_manage,can_edit,can_download,can_delete) values (#{user.id},#{sop.id},#{f},#{f},#{f},#{f},#{f});")
        Sop.connection.execute("insert into sop_auth_lookup(user_id,asset_id,can_view,can_manage,can_edit,can_download,can_delete) values (#{user.id},#{sop.id},#{f},#{f},#{f},#{f},#{f});")
        assert_equal 3, Sop.lookup_count_for_user(user.id)
        assert_equal 4, Sop.connection.select_one('select count(*) from sop_auth_lookup;').values[0].to_i
        refute_empty Sop.lookup_class.select(:asset_id, :user_id).group(:asset_id, :user_id).having("count(*) > 1")
        Sop.remove_invalid_auth_lookup_entries
        assert_equal 1, Sop.lookup_count_for_user(user.id)
        assert_equal 2, Sop.connection.select_one('select count(*) from sop_auth_lookup;').values[0].to_i
        assert_empty Sop.lookup_class.select(:asset_id, :user_id).group(:asset_id, :user_id).having("count(*) > 1")
        assert_equal 1, Sop.lookup_class.where(asset_id:sop.id, user_id:user.id).size
      end
    end
  end

  test 'items_missing_from_authlookup' do
    with_config_value :auth_lookup_enabled, true do
      user = FactoryBot.create(:user)
      user2 = FactoryBot.create(:user)
      doc = FactoryBot.create(:document)
      doc.update_lookup_table(user2)

      assert_equal [doc],Document.items_missing_from_authlookup(user)
      assert_empty Document.items_missing_from_authlookup(user2)

      doc.update_lookup_table(user)
      assert_empty Document.items_missing_from_authlookup(user)

      # check for anonymous user
      assert_empty Document.items_missing_from_authlookup(nil)
      Document.lookup_class.where(user_id:0).last.delete
      assert_equal [doc],Document.items_missing_from_authlookup(nil)

    end
  end

  test 'people flagged as having left a project cannot see project-shared items' do
    person = FactoryBot.create(:former_project_person)
    project = person.projects.first
    active_person = FactoryBot.create(:person, project: project)

    assert person.current_projects.empty?
    assert_includes person.former_projects, project
    assert_includes active_person.current_projects, project
    assert_includes project.former_people, person
    assert_includes project.current_people, active_person

    data = FactoryBot.create(:data_file, policy: FactoryBot.create(:private_policy,
                                               permissions: [FactoryBot.create(:edit_permission, contributor: project)]))

    assert data.can_view?(active_person)
    assert data.can_edit?(active_person)
    refute data.can_view?(person)
    refute data.can_edit?(person)
  end

  test 'people flagged as leaving a project in the future can still see project-shared items' do
    person = FactoryBot.create(:future_former_project_person)
    project = person.projects.first
    active_person = FactoryBot.create(:person, project: project)

    assert_includes person.current_projects, project
    assert_empty person.former_projects
    assert_includes active_person.current_projects, project
    assert_includes project.current_people, person
    assert_includes project.current_people, active_person

    data = FactoryBot.create(:data_file, policy: FactoryBot.create(:private_policy,
                                               permissions: [FactoryBot.create(:edit_permission, contributor: project)]))

    assert data.can_view?(active_person)
    assert data.can_edit?(active_person)
    assert data.can_view?(person)
    assert data.can_edit?(person)
  end
end