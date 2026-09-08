require 'test_helper'
require 'oidc_test_helper'

class AccessTokenVerifierTest < ActiveSupport::TestCase
  include OidcTestHelper

  def setup
    # Both the cached key set and the recorded requests would otherwise carry over between tests.
    WebMock.reset!
    clear_rails_cache
    stub_oidc_provider
  end

  def teardown
    clear_rails_cache
  end

  test 'accepts a token signed by the provider' do
    claims = verify(signed_oidc_token)

    assert_not_nil claims
    assert_equal 'oidc-subject-1', claims['sub']
  end

  test 'accepts a token dated a moment ahead of this clock' do
    assert_not_nil verify(signed_oidc_token({ iat: 30.seconds.from_now.to_i,
                                              nbf: 30.seconds.from_now.to_i }))
  end

  test 'accepts a token signed with an elliptic curve key' do
    ec = OpenSSL::PKey::EC.generate('prime256v1')
    private_jwk = JSON::JWK.new(ec, kid: 'ec-key')
    stub_oidc_key_set(keys: [JSON::JWK.new(private_jwk.to_h.except(:d, 'd'), kid: 'ec-key')])

    assert_not_nil verify(signed_oidc_token({}, key: private_jwk, alg: :ES256))
  end

  test 'accepts a token with no key id when the provider offers a single key' do
    token = JSON::JWT.new(default_oidc_claims).sign(oidc_rsa_key, :RS256).to_s

    assert_nil JSON::JWT.decode(token, :skip_verification).header[:kid]
    assert_not_nil verify(token)
  end

  test 'reaches the provider only once for repeated tokens' do
    2.times { assert_not_nil verify(signed_oidc_token) }

    assert_requested :get, "#{OIDC_ISSUER}/.well-known/openid-configuration", times: 1
    assert_requested :get, "#{OIDC_ISSUER}/jwks", times: 1
  end

  test 'rejects an expired token' do
    assert_nil verify(signed_oidc_token({ exp: 10.minutes.ago.to_i }))
  end

  test 'rejects a token that has only just expired' do
    assert_nil verify(signed_oidc_token({ exp: 30.seconds.ago.to_i }))
  end

  test 'rejects a token with no expiry' do
    assert_nil verify(JSON::JWT.new(default_oidc_claims.except(:exp)).sign(oidc_signing_key, :RS256).to_s)
  end

  test 'rejects a token that is not yet valid' do
    assert_nil verify(signed_oidc_token({ nbf: 10.minutes.from_now.to_i }))
  end

  test 'rejects a token issued in the future' do
    assert_nil verify(signed_oidc_token({ iat: 10.minutes.from_now.to_i }))
  end

  test 'rejects a token from another issuer' do
    assert_nil verify(signed_oidc_token({ iss: 'https://evil.example.com/oidc' }))
  end

  test 'rejects a token with no subject' do
    assert_nil verify(signed_oidc_token({ sub: '' }))
    assert_nil verify(JSON::JWT.new(default_oidc_claims.except(:sub)).sign(oidc_signing_key, :RS256).to_s)
  end

  test 'rejects a token whose payload has been altered' do
    header, payload, signature = signed_oidc_token.split('.')
    altered = Base64.urlsafe_encode64(
      JSON.parse(Base64.urlsafe_decode64(payload)).merge('sub' => 'somebody-else').to_json, padding: false
    )

    assert_nil verify([header, altered, signature].join('.'))
  end

  test 'rejects a token signed by a different key claiming the provider key id' do
    impostor = JSON::JWK.new(OpenSSL::PKey::RSA.generate(2048), kid: OIDC_KID)

    assert_nil verify(signed_oidc_token({}, key: impostor))
  end

  test 'rejects an unsigned token' do
    unsigned = JSON::JWT.new(default_oidc_claims)
    unsigned.header[:alg] = :none
    unsigned.header[:kid] = OIDC_KID

    assert_nil verify(unsigned.to_s)
  end

  test 'rejects a token signed with the provider public key as a shared secret' do
    forged = JSON::JWT.new(default_oidc_claims)
    forged.header[:kid] = OIDC_KID

    assert_nil verify(forged.sign(oidc_rsa_key.public_key.to_pem, :HS256).to_s)
  end

  test 'rejects a token naming a key the provider does not offer' do
    assert_nil verify(signed_oidc_token({}, key: JSON::JWK.new(oidc_rsa_key, kid: 'no-such-key')))
  end

  test 'refetches the key set once for an unknown key id' do
    verify(signed_oidc_token({}, key: JSON::JWK.new(oidc_rsa_key, kid: 'no-such-key')))

    assert_requested :get, "#{OIDC_ISSUER}/jwks", times: 2
  end

  test 'does not refetch the key set again within the cooldown' do
    unknown = JSON::JWK.new(oidc_rsa_key, kid: 'no-such-key')
    2.times { assert_nil verify(signed_oidc_token({}, key: unknown)) }

    assert_requested :get, "#{OIDC_ISSUER}/jwks", times: 2
  end

  test 'picks up a rotated provider key' do
    rotated = OpenSSL::PKey::RSA.generate(2048)
    stub_oidc_key_set(keys: [oidc_public_key(kid: 'rotated-key', key: rotated)])

    assert_not_nil verify(signed_oidc_token({}, key: JSON::JWK.new(rotated, kid: 'rotated-key')))
  end

  test 'rejects a token when discovery fails, and stops asking for a while' do
    WebMock.reset!
    clear_rails_cache
    stub_oidc_discovery(status: 500)

    assert_nil verify(signed_oidc_token)
    assert_nil verify(signed_oidc_token)

    assert_requested :get, "#{OIDC_ISSUER}/.well-known/openid-configuration", times: 1
  end

  test 'rejects a token when the key set cannot be fetched' do
    WebMock.reset!
    clear_rails_cache
    stub_oidc_discovery
    stub_request(:get, "#{OIDC_ISSUER}/jwks").to_timeout

    assert_nil verify(signed_oidc_token)
  end

  test 'ignores a credential that is not a token from the provider' do
    ['', 'a', SecureRandom.urlsafe_base64(40).first(40), 'not-a-jwt', 'a.b', 'a.b.c.d'].each do |credential|
      assert_nil verify(credential), "expected #{credential.inspect} to be ignored"
    end

    assert_not_requested :get, "#{OIDC_ISSUER}/.well-known/openid-configuration"
    assert_not_requested :get, "#{OIDC_ISSUER}/jwks"
  end

  test 'ignores a token beyond the size it is willing to read' do
    assert_nil verify("#{'a' * 9000}.b.c")

    assert_not_requested :get, "#{OIDC_ISSUER}/jwks"
  end

  test 'does nothing unless every setting is in place' do
    token = signed_oidc_token

    with_oidc_api_enabled do
      with_config_value(:omniauth_oidc_api_enabled, false) { assert_nil described_verify(token) }
      with_config_value(:omniauth_oidc_enabled, false) { assert_nil described_verify(token) }
      with_config_value(:omniauth_enabled, false) { assert_nil described_verify(token) }
      with_config_value(:omniauth_oidc_issuer, '') { assert_nil described_verify(token) }
    end

    assert_not_requested :get, "#{OIDC_ISSUER}/.well-known/openid-configuration"
  end

  test 'accepts any audience when none is configured' do
    assert_not_nil verify(signed_oidc_token({ aud: 'somebody-else', azp: 'somebody-else' }))
  end

  test 'treats a list of only separators as no audience at all' do
    assert_not_nil verify(signed_oidc_token({ aud: 'somebody-else', azp: 'somebody-else' }),
                          audiences: ' , ')
  end

  test 'accepts a configured audience given as a string' do
    assert_not_nil verify(signed_oidc_token({ aud: 'seek-client', azp: nil }), audiences: 'seek-client')
  end

  test 'accepts a configured audience among several' do
    assert_not_nil verify(signed_oidc_token({ aud: %w[account seek-client], azp: nil }),
                          audiences: 'other-client, seek-client')
  end

  test 'accepts the authorised party when the audience does not match' do
    assert_not_nil verify(signed_oidc_token({ aud: 'account', azp: 'cli-client' }), audiences: 'cli-client')
  end

  test 'rejects a token for an audience that is not configured' do
    assert_nil verify(signed_oidc_token({ aud: 'account', azp: 'other-client' }), audiences: 'cli-client')
  end

  private

  def verify(token, audiences: '')
    with_oidc_api_enabled(audiences: audiences) { described_verify(token) }
  end

  def described_verify(token)
    Seek::Oidc::AccessTokenVerifier.verify(token)
  end
end
