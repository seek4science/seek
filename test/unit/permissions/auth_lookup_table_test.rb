require 'test_helper'

class AuthLookupTableTest < ActiveSupport::TestCase
  def setup
    @val = Seek::Config.auth_lookup_enabled
    Seek::Config.auth_lookup_enabled = true
    AuthLookupUpdateQueue.destroy_all
    Delayed::Job.destroy_all
  end

  def teardown
    Seek::Config.auth_lookup_enabled = @val
  end

  test 'Removes a user from the lookup tables when they are destroyed' do #
    disable_authorization_checks do
      Person.destroy_all
      User.destroy_all
      Assay.destroy_all
      DataFile.destroy_all
    end

    u = Factory(:user)
    u2 = Factory(:user)
    a = Factory(:assay, contributor: u2.person)
    d = Factory(:data_file, contributor: u2.person)
    a.update_lookup_table_for_all_users
    d.update_lookup_table_for_all_users

    assert_equal (User.count + 1), a.auth_lookup.count
    assert_equal (User.count + 1), d.auth_lookup.count

    assert_difference('a.auth_lookup.count', -1) do
      assert_difference('d.auth_lookup.count', -1) do
        disable_authorization_checks { u.destroy }
      end
    end

    a_user_ids = a.auth_lookup.pluck(:user_id)
    d_user_ids = d.auth_lookup.pluck(:user_id)

    assert_not_includes a_user_ids, u.id
    assert_not_includes d_user_ids, u.id

    assert_equal (User.count + 1), a.auth_lookup.count
    assert_equal (User.count + 1), d.auth_lookup.count
  end

  test 'Updates auth lookup for all users' do
    person = Factory(:person)
    User.current_user = person.user
    [:assay, :document, :data_file, :sample].each do |type|
      item = Factory(type, contributor: person, policy: Factory(:private_policy))

      assert_equal 2, item.auth_lookup.count, "Should have 1 entry each for logged in user and anonymous user (nil)"
      auth = item.auth_lookup.to_a

      anon_auth = auth.detect { |a| a.user_id == 0 }
      refute anon_auth.can_view
      refute anon_auth.can_edit
      refute anon_auth.can_download
      refute anon_auth.can_manage
      refute anon_auth.can_delete

      user_auth = auth.detect { |a| a.user_id != 0 }
      assert_equal person.user, user_auth.user
      assert user_auth.can_view
      assert user_auth.can_edit
      assert user_auth.can_download
      assert user_auth.can_manage
      assert user_auth.can_delete

      item.update_lookup_table_for_all_users

      assert_equal (User.count + 1), item.auth_lookup.count, "Should have 1 entry for each user, and 1 extra for the anonymous user"

      # Check each auth entry
      item.auth_lookup.includes(:user).each do |entry|
        user = entry.user
        AuthLookup::ABILITIES.each do |ability|
          assert_equal item.authorized_for_action(user, ability), entry.send("can_#{ability}"), "Mismatch in #{type} auth lookup for user: #{user} and ability: #{ability}"
        end
      end
    end
  end

  test 'Initializes auth lookup for item with existing entries' do
    person = Factory(:person)
    User.current_user = person.user
    doc = Factory(:document, contributor: person, policy: Factory(:public_policy))
    doc.update_lookup_table_for_all_users

    assert_no_difference(-> { doc.auth_lookup.count }) do
      doc.auth_lookup.prepare
    end

    refute doc.auth_lookup.pluck(:can_view).any?, "All entries should be false"
  end

  test 'Initializes auth lookup for item with no entries' do
    person = Factory(:person)
    User.current_user = person.user
    doc = Factory(:document, contributor: person, policy: Factory(:public_policy))
    doc.auth_lookup.delete_all

    assert_equal 0, doc.auth_lookup.count

    diff = User.count + 1
    assert_difference(-> { doc.auth_lookup.count }, diff) do
      doc.auth_lookup.prepare
    end

    refute doc.auth_lookup.pluck(:can_view).any?, "All entries should be false"
  end

  test 'Batch updates' do
    disable_authorization_checks do
      Person.destroy_all
      User.destroy_all
      Sop.destroy_all
    end

    person = Factory(:person)
    project = person.projects.first
    project_buddy = Factory(:person, project: project)
    another_person = Factory(:person)
    User.current_user = person.user

    sop = Factory(:sop, contributor: person, policy: Factory(:publicly_viewable_policy,
                                                             permissions: [Permission.new(contributor: project, access_type: Policy::EDITING)]))

    cont = person.user.id
    proj = project_buddy.user.id
    user = another_person.user.id
    anon = 0

    sop.auth_lookup.prepare

    assert_equal [false, false, false, false, false], sop.auth_lookup.where(user: cont).first.as_array
    assert_equal [false, false, false, false, false], sop.auth_lookup.where(user: proj).first.as_array
    assert_equal [false, false, false, false, false], sop.auth_lookup.where(user: user).first.as_array
    assert_equal [false, false, false, false, false], sop.auth_lookup.where(user: anon).first.as_array

    # Overwrite, using array
    sop.auth_lookup.batch_update([true, true, true, false, false])
    assert_equal [true, true, true, false, false], sop.auth_lookup.where(user: cont).first.as_array
    assert_equal [true, true, true, false, false], sop.auth_lookup.where(user: proj).first.as_array
    assert_equal [true, true, true, false, false], sop.auth_lookup.where(user: user).first.as_array
    assert_equal [true, true, true, false, false], sop.auth_lookup.where(user: anon).first.as_array

    # Without overwrite, using array
    sop.auth_lookup.batch_update([false, false, false, true, false], false)
    assert_equal [true, true, true, true, false], sop.auth_lookup.where(user: cont).first.as_array
    assert_equal [true, true, true, true, false], sop.auth_lookup.where(user: proj).first.as_array
    assert_equal [true, true, true, true, false], sop.auth_lookup.where(user: user).first.as_array
    assert_equal [true, true, true, true, false], sop.auth_lookup.where(user: anon).first.as_array

    # Reset
    sop.auth_lookup.prepare

    # Selective overwrite, using array
    sop.auth_lookup.where(user: cont).batch_update([true, true, true, true, true])
    assert_equal [true, true, true, true, true], sop.auth_lookup.where(user: cont).first.as_array
    assert_equal [false, false, false, false, false], sop.auth_lookup.where(user: proj).first.as_array
    assert_equal [false, false, false, false, false], sop.auth_lookup.where(user: user).first.as_array
    assert_equal [false, false, false, false, false], sop.auth_lookup.where(user: anon).first.as_array

    # Without overwrite, using policy
    sop.auth_lookup.batch_update(sop.policy, false)
    assert_equal [true, true, true, true, true], sop.auth_lookup.where(user: cont).first.as_array
    assert_equal [true, false, false, false, false], sop.auth_lookup.where(user: proj).first.as_array
    assert_equal [true, false, false, false, false], sop.auth_lookup.where(user: user).first.as_array
    assert_equal [true, false, false, false, false], sop.auth_lookup.where(user: anon).first.as_array

    # Overwrite, using project permission
    perm = sop.policy.permissions.first
    assert_equal 2, perm.affected_people.count
    assert_includes perm.affected_people, person
    assert_includes perm.affected_people, project_buddy
    sop.auth_lookup.where(user_id: perm.affected_people.map(&:user)).batch_update(perm)
    assert_equal [true, true, true, false, false], sop.auth_lookup.where(user: cont).first.as_array
    assert_equal [true, true, true, false, false], sop.auth_lookup.where(user: proj).first.as_array
    assert_equal [true, false, false, false, false], sop.auth_lookup.where(user: user).first.as_array
    assert_equal [true, false, false, false, false], sop.auth_lookup.where(user: anon).first.as_array
  end
end
