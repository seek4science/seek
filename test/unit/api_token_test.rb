require 'test_helper'

class ApiTokenTest < ActiveSupport::TestCase
  test 'recognises what could be an api token' do
    assert ApiToken.plausible_token?(ApiToken.random_api_token)
    assert ApiToken.plausible_token?('a-token_of-another-length')

    assert_not ApiToken.plausible_token?('header.payload.signature'), 'a JWT is not an API token'
    assert_not ApiToken.plausible_token?('')
    assert_not ApiToken.plausible_token?('a')
    assert_not ApiToken.plausible_token?(nil)
  end

  test 'plain text token available after create' do
    user = FactoryBot.create(:user)

    api_token = user.api_tokens.build(title: 'Test')

    assert api_token.save
    assert_match /[-_a-zA-Z0-9]{#{ApiToken::API_TOKEN_LENGTH}}/, api_token.token
    assert_match /[a-f0-9]{64}/, api_token.encrypted_token
  end

  test 'plain text token not available at any other time' do
    api_token = FactoryBot.create(:api_token)
    api_token = ApiToken.find(api_token.id) # Have to reload it...

    assert_nil api_token.token
    assert_match /[a-f0-9]{64}/, api_token.encrypted_token
  end
end
