require 'test_helper'
require 'minitest/mock'

class AuthLookupDeleteJobTest < ActiveSupport::TestCase
  test 'perform for asset' do
    disable_authorization_checks do
      Person.destroy_all
      User.destroy_all
      Assay.destroy_all
      DataFile.destroy_all
    end

    u = FactoryBot.create(:user)
    u2 = FactoryBot.create(:user)
    a = FactoryBot.create(:assay, contributor: u2.person)
    d = FactoryBot.create(:data_file, contributor: u2.person)
    a.update_lookup_table_for_all_users
    d.update_lookup_table_for_all_users

    assert_equal (User.count + 1), a.auth_lookup.count
    assert_equal (User.count + 1), d.auth_lookup.count

    assert Assay::AuthLookup.where(user_id: u.id).exists?
    assert DataFile::AuthLookup.where(user_id: u.id).exists?
    assert DataFile::AuthLookup.where(user_id: u2.id).exists?
    assert DataFile::AuthLookup.where(user_id: 0).exists?

    assert_difference('DataFile::AuthLookup.count', -3) do # 2 users + anonymous
      assert_no_difference('Assay::AuthLookup.count') do
        AuthLookupDeleteJob.perform_now('DataFile', d.id)
      end
    end

    assert Assay::AuthLookup.where(user_id: u.id).exists?
    refute DataFile::AuthLookup.where(user_id: u.id).exists?
    refute DataFile::AuthLookup.where(user_id: u2.id).exists?
    refute DataFile::AuthLookup.where(user_id: 0).exists?
  end

  test 'perform when asset record no longer exists' do
    assert_nothing_raised do
      assert_no_difference('DataFile::AuthLookup.count') do
        AuthLookupDeleteJob.perform_now('DataFile', (DataFile.maximum(:id) || 0) + 10)
      end
    end
  end

  test 'perform when user record no longer exists' do
    assert_nothing_raised do
      assert_no_difference('DataFile::AuthLookup.count') do
        AuthLookupDeleteJob.perform_now('User', (User.maximum(:id) || 0) + 10)
      end
    end
  end

  test 'perform for user' do
    disable_authorization_checks do
      Person.destroy_all
      User.destroy_all
      Assay.destroy_all
      DataFile.destroy_all
    end

    u = FactoryBot.create(:user)
    u2 = FactoryBot.create(:user)
    a = FactoryBot.create(:assay, contributor: u2.person)
    d = FactoryBot.create(:data_file, contributor: u2.person)
    a.update_lookup_table_for_all_users
    d.update_lookup_table_for_all_users

    assert_equal (User.count + 1), a.auth_lookup.count
    assert_equal (User.count + 1), d.auth_lookup.count

    assert Assay::AuthLookup.where(user_id: u.id).exists?
    assert DataFile::AuthLookup.where(user_id: u.id).exists?
    assert DataFile::AuthLookup.where(user_id: u2.id).exists?
    assert DataFile::AuthLookup.where(user_id: 0).exists?

    assert_difference('DataFile::AuthLookup.count', -1) do
      assert_difference('Assay::AuthLookup.count', -1) do
        AuthLookupDeleteJob.perform_now('User', u.id)
      end
    end

    refute Assay::AuthLookup.where(user_id: u.id).exists?
    refute DataFile::AuthLookup.where(user_id: u.id).exists?
    assert DataFile::AuthLookup.where(user_id: u2.id).exists?
    assert DataFile::AuthLookup.where(user_id: 0).exists?
  end
end
