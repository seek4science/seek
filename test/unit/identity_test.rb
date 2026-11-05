require 'test_helper'

class IdentityTest < ActiveSupport::TestCase
  test 'will not take a provider and uid another identity already holds' do
    FactoryBot.create(:user).identities.create!(provider: 'oidc', uid: 'subject-1')

    duplicate = FactoryBot.create(:user).identities.build(provider: 'oidc', uid: 'subject-1')

    refute duplicate.valid?
    assert_includes duplicate.errors[:uid], 'has already been taken'
  end

  test 'takes a uid another provider holds' do
    FactoryBot.create(:user).identities.create!(provider: 'ldap', uid: 'subject-1')

    identity = FactoryBot.create(:user).identities.build(provider: 'oidc', uid: 'subject-1')

    assert identity.valid?
  end
end
