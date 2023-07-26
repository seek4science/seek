require 'test_helper'

class SpecialAuthCodeTest < ActiveSupport::TestCase
  test 'only managers can add/remove auth codes' do
    item = FactoryBot.create(:data_file, policy: FactoryBot.create(:all_sysmo_viewable_policy), contributor: FactoryBot.create(:person))

    User.with_current_user(FactoryBot.create(:user)) do
      assert_raise RuntimeError do
        item.special_auth_codes << SpecialAuthCode.new
      end
    end

    assert item.special_auth_codes.empty?

    User.with_current_user(item.contributor.user) do
      assert item.can_manage?
      item.special_auth_codes << SpecialAuthCode.new
      refute item.special_auth_codes.empty?
    end

    User.with_current_user(FactoryBot.create(:user)) do
      assert_raise RuntimeError do
        item.special_auth_codes = []
      end
      refute item.special_auth_codes.empty?
    end

    User.with_current_user(item.contributor.user) do
      item.special_auth_codes = []
      assert item.special_auth_codes.empty?
    end
  end

  test 'only the manager of an item can edit its auth codes' do
    owner = FactoryBot.create(:person)
    code = User.with_current_user(owner.user) do
      FactoryBot.create(:special_auth_code, asset: FactoryBot.create(:data_file, contributor: owner))
    end

    code.expiration_date = Time.now
    User.with_current_user(FactoryBot.create(:user)) do
      refute code.save
    end

    User.with_current_user(owner.user) do
      assert code.save
    end
  end
end
