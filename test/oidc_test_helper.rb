require 'json/jwt'

# Builds access tokens, and stubs the provider that verifies them, for tests of OpenID Connect
# authentication. The issuer matches the one set for the test environment in
# config/initializers/seek_testing.rb.
module OidcTestHelper
  OIDC_ISSUER = 'https://example.com/oidc'.freeze
  OIDC_KID = 'seek-test-key'.freeze

  # A key pair for the provider, and the same key pair published as its key set. Signing with the
  # private JWK rather than the bare OpenSSL key is what puts the key id into the token's header.
  def oidc_signing_key
    @oidc_signing_key ||= JSON::JWK.new(oidc_rsa_key, kid: OIDC_KID)
  end

  def oidc_public_key(kid: OIDC_KID, key: oidc_rsa_key)
    JSON::JWK.new(key.public_key, kid: kid)
  end

  def oidc_rsa_key
    @oidc_rsa_key ||= OpenSSL::PKey::RSA.generate(2048)
  end

  def signed_oidc_token(claims = {}, key: oidc_signing_key, alg: :RS256)
    JSON::JWT.new(default_oidc_claims.merge(claims)).sign(key, alg).to_s
  end

  def default_oidc_claims
    { iss: OIDC_ISSUER, sub: 'oidc-subject-1', aud: 'seek-client', azp: 'cli-client',
      exp: 10.minutes.from_now.to_i, iat: Time.now.to_i }
  end

  # The discovery document's own issuer has to equal the one configured, or the library rejects it.
  def stub_oidc_provider(keys: [oidc_public_key], issuer: OIDC_ISSUER)
    stub_oidc_discovery(issuer: issuer)
    stub_oidc_key_set(keys: keys, issuer: issuer)
  end

  def stub_oidc_discovery(issuer: OIDC_ISSUER, status: 200)
    body = { issuer: issuer,
             authorization_endpoint: "#{issuer}/auth",
             token_endpoint: "#{issuer}/token",
             jwks_uri: "#{issuer}/jwks",
             response_types_supported: %w[code],
             subject_types_supported: %w[public],
             id_token_signing_alg_values_supported: %w[RS256] }
    stub_request(:get, "#{issuer}/.well-known/openid-configuration")
      .to_return(status: status, body: body.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_oidc_key_set(keys: [oidc_public_key], issuer: OIDC_ISSUER)
    stub_request(:get, "#{issuer}/jwks")
      .to_return(status: 200, body: JSON::JWK::Set.new(*keys).as_json.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  def with_oidc_api_enabled(audiences: '', &block)
    with_config_values({ omniauth_enabled: true, omniauth_oidc_enabled: true,
                         omniauth_oidc_api_enabled: true, omniauth_oidc_issuer: OIDC_ISSUER,
                         omniauth_oidc_api_audiences: audiences }, &block)
  end
end
