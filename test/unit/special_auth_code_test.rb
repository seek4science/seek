require 'test_helper'

class SpecialAuthCodeTest < ActiveSupport::TestCase
  test "only managers can add/remove auth codes" do
    item = Factory(:data_file, :policy => Factory(:all_sysmo_viewable_policy))
    User.current_user = Factory(:user)

    item.special_auth_codes << Factory(:special_auth_code)
    assert item.special_auth_codes.empty?

    User.current_user = item.contributor
    item.special_auth_codes << Factory(:special_auth_code)
    assert !item.special_auth_codes.empty?

    User.current_user = Factory(:user)
    item.special_auth_codes = []
    assert !item.special_auth_codes.empty?

    User.current_user = item.contributor
    item.special_auth_codes = []
    assert item.special_auth_codes.empty?
  end

  test "auth codes allow access to private items until they expire" do
    auth_code = Factory :special_auth_code,
                        :expiration_date => (Time.now + 1.days),
                        :asset => Factory(:data_file, :policy => Factory(:private_policy))
    item = auth_code.asset
    User.current_user = Factory(:user)

    assert !item.can_view?
    assert !item.can_download?
    SpecialAuthCode.with_auth_code auth_code.code do
      assert item.can_view?
      assert item.can_download?
    end

    disable_authorization_checks {auth_code.expiration_date = Time.now - 1.days; auth_code.save! }
    item.reload
    SpecialAuthCode.with_auth_code auth_code.code do
      assert !item.can_view?
      assert !item.can_download?
    end
  end

  test "only the manager of an item can edit its auth codes" do
    Factory :data_file, :policy => Factory(:all_sysmo_viewable_policy), :special_auth_codes => [code = Factory(:special_auth_code)]
    User.current_user = Factory(:user)

    code.expiration_date = Time.now
    assert !code.save
  end
end
