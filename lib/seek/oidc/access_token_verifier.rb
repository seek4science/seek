module Seek
  # See Seek::OIDC::Discovery for what this namespace's spelling depends on.
  module OIDC
    # Checks whether a bearer token is a currently valid access token issued by the OpenID Connect
    # provider configured for this instance, verifying its signature against the provider's keys.
    class AccessTokenVerifier
      # The omniauth name given to the generic OpenID Connect provider by
      # Seek::Config.omniauth_oidc_config, and so the value held in identities.provider.
      PROVIDER = 'oidc'.freeze

      # Asymmetric algorithms only, and ruby-jwt insists on being handed the list. It compares the
      # token's algorithm against this before it looks up any key, which is what rejects an
      # unsigned token, and one signed HS256 using the provider's published public key as the
      # shared secret. Strings here, unlike json-jwt, which wants symbols.
      SIGNING_ALGORITHMS = %w[RS256 RS384 RS512 PS256 PS384 PS512 ES256 ES384 ES512].freeze

      # Leeway for the claims that place a token in the future, so that a token minted moments ago
      # is not refused merely because this clock lags the provider's. Deliberately not allowed
      # against expiry: a token refused as expired is simply retried with a fresh one, whereas
      # honouring an expired one would lengthen the only window in which a token the provider has
      # revoked still works here.
      FUTURE_CLAIM_LEEWAY = 60
      MAX_TOKEN_BYTES = 8192

      class << self
        # Is an access token from the provider accepted as a credential for the API? Reading the
        # settings per request means an administrator turning this on needs no restart, unlike the
        # provider itself, which is wired into the middleware at boot.
        def enabled?
          Seek::Config.omniauth_enabled &&
            Seek::Config.omniauth_oidc_enabled &&
            Seek::Config.omniauth_oidc_api_enabled &&
            Seek::Config.omniauth_oidc_issuer.present?
        end

        def verify(token)
          new(token).verify
        end
      end

      def initialize(token)
        @token = token.to_s
      end

      # The token's claims, or nil if it is not a credential this instance accepts. Never raises:
      # an unusable credential has to mean nobody is logged in, and a failure of the provider or of
      # a library must not turn every request carrying a bearer token into a 500.
      def verify
        return nil unless self.class.enabled?
        return nil unless plausible_jwt?

        claims, = ::JWT.decode(@token, nil, true, decode_options)
        return nil if claims['sub'].blank?
        return nil unless audience_accepted?(claims)

        claims
      rescue StandardError => e
        Rails.logger.info("Rejected OpenID Connect access token: #{e.class}: #{e.message}")
        nil
      end

      private

      # Runs on every request carrying an Authorization header, so it has to be cheap. SEEK's own
      # API tokens are 40 characters of urlsafe base64 and so contain no dots, which keeps them
      # away from the provider entirely.
      def plausible_jwt?
        @token.bytesize.between?(2, MAX_TOKEN_BYTES) && @token.count('.') == 2
      end

      # Expiry and not-before are verified by default. exp_leeway is stated even though nought is
      # the default, because what matters here is that it differs from nbf_leeway. iat is left
      # unverified: it describes a token rather than bounding its validity, and ruby-jwt allows it
      # no leeway at all, so checking it would refuse a token minted a moment ago by a clock
      # slightly ahead of this one. required_claims asserts only that a claim is present, hence
      # the separate check for a blank subject.
      #
      # allow_nil_kid lets a provider that does not name the key it signed with still work, though
      # only where it publishes a single key: ruby-jwt takes the first in the set rather than
      # trying each.
      def decode_options
        {
          algorithms: SIGNING_ALGORITHMS,
          jwks: ->(options) { discovery.key_set(invalidate: options[:invalidate]) },
          allow_nil_kid: true,
          required_claims: %w[exp sub iss],
          iss: Seek::Config.omniauth_oidc_issuer,
          verify_iss: true,
          exp_leeway: 0,
          nbf_leeway: FUTURE_CLAIM_LEEWAY
        }
      end

      # An empty list means the instance has chosen not to check the audience at all, in which case
      # any token the provider signed for anybody is accepted. azp is considered alongside aud
      # because a provider commonly names the resource in aud and the calling application in azp,
      # and it is the calling application an administrator wants to name here. ruby-jwt's own aud
      # verification knows nothing of azp, so this stays by hand.
      def audience_accepted?(claims)
        accepted = Seek::Config.omniauth_oidc_api_audience_list
        return true if accepted.empty?

        presented = ([*claims['aud']] + [claims['azp']]).compact.map(&:to_s)
        presented.intersect?(accepted)
      end

      def discovery
        @discovery ||= Discovery.new(Seek::Config.omniauth_oidc_issuer)
      end
    end
  end
end
