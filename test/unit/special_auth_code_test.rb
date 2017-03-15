require 'test_helper'

class SpecialAuthCodeTest < ActiveSupport::TestCase
  test 'only managers can add/remove auth codes' do
    item = Factory(:data_file, policy: Factory(:all_sysmo_viewable_policy))
    User.current_user = Factory(:user)

    assert_raise RuntimeError do
      item.special_auth_codes << Factory(:special_auth_code)
    end
    assert item.special_auth_codes.empty?

    User.current_user = item.contributor
    item.special_auth_codes << Factory(:special_auth_code)
    assert !item.special_auth_codes.empty?

    User.current_user = Factory(:user)
    assert_raise RuntimeError do
      item.special_auth_codes = []
    end
    assert !item.special_auth_codes.empty?

    User.current_user = item.contributor
    item.special_auth_codes = []
    assert item.special_auth_codes.empty?
  end

  test 'only the manager of an item can edit its auth codes' do
    code = Factory(:special_auth_code)
    User.current_user = Factory(:user)

    code.expiration_date = Time.now
    df = code.asset

    assert !code.save
    User.current_user = df.contributor

    assert code.save!
  end
end
