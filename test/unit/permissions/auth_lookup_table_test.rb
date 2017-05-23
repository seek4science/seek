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

    assert_equal (User.count + 1), a.lookup_count
    assert_equal (User.count + 1), d.lookup_count

    assert_difference('a.lookup_count', -1) do
      assert_difference('d.lookup_count', -1) do
        disable_authorization_checks { u.destroy }
      end
    end

    a_user_ids = ActiveRecord::Base.connection.select_values("select user_id from #{Assay.lookup_table_name}")
    d_user_ids = ActiveRecord::Base.connection.select_values("select user_id from #{DataFile.lookup_table_name}")

    assert_not_includes a_user_ids, u.id
    assert_not_includes d_user_ids, u.id

    assert_equal (User.count + 1), a.lookup_count
    assert_equal (User.count + 1), d.lookup_count
  end
end
