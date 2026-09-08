module Seek
  # See Seek::Oidc::Discovery for why this namespace is spelled Oidc.
  module Oidc
    # Checks whether a bearer token is a currently valid access token issued by the OpenID Connect
    # provider configured for this instance, verifying its signature against the provider's keys.
    class AccessTokenVerifier
      # The omniauth name given to the generic OpenID Connect provider by
      # Seek::Config.omniauth_oidc_config, and so the value held in identities.provider.
      PROVIDER = 'oidc'.freeze

      # Asymmetric algorithms only. Handing this list to JSON::JWT.decode is what rejects an
      # unsigned token, and a token signed HS256 using the provider's public key as the shared
      # secret. JSON::JWS#verify! compares against alg.to_sym, so these have to be symbols.
      SIGNING_ALGORITHMS = %i[RS256 RS384 RS512 PS256 PS384 PS512 ES256 ES384 ES512].freeze

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

        claims = verified_claims
        return nil if claims.nil?
        return nil unless claims_acceptable?(claims)

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

      def verified_claims
        header = ::JSON::JWT.decode(@token, :skip_verification).header
        return nil unless SIGNING_ALGORITHMS.include?(header[:alg]&.to_sym)

        candidate_keys(header[:kid]).each do |jwk|
          claims = decode(jwk)
          return claims if claims
        end

        nil
      end

      # One key at a time, never the whole set: handed a set, json-jwt chooses the key itself from
      # the key id the token asks for, which takes that choice out of our hands.
      def decode(jwk)
        ::JSON::JWT.decode(@token, jwk, SIGNING_ALGORITHMS)
      rescue ::JSON::JWT::Exception, ::OpenSSL::OpenSSLError
        nil
      end

      # Providers that name the key they signed with are the common case; trying each key in turn
      # covers the rest, bounded by the size of the provider's key set.
      def candidate_keys(kid)
        return [discovery.signing_key(kid)].compact if kid.present?

        discovery.signing_keys
      end

      def claims_acceptable?(claims)
        claims[:iss] == Seek::Config.omniauth_oidc_issuer &&
          claims[:sub].present? &&
          current?(claims) &&
          audience_accepted?(claims)
      end

      # A token has to say when it expires, and must not be dated for use later on.
      def current?(claims)
        now = Time.now.to_i
        expiry = time_claim(claims, :exp)
        return false if expiry.nil? || expiry <= now

        starts = [time_claim(claims, :nbf), time_claim(claims, :iat)].compact
        starts.none? { |from| from > (now + FUTURE_CLAIM_LEEWAY) }
      end

      def time_claim(claims, name)
        claims[name].presence&.to_i
      end

      # An empty list means the instance has chosen not to check the audience at all, in which case
      # any token the provider signed for anybody is accepted. azp is considered alongside aud
      # because a provider commonly names the resource in aud and the calling application in azp,
      # and it is the calling application an administrator wants to name here.
      def audience_accepted?(claims)
        accepted = Seek::Config.omniauth_oidc_api_audience_list
        return true if accepted.empty?

        presented = (Array(claims[:aud]) + [claims[:azp]]).compact.map(&:to_s)
        presented.intersect?(accepted)
      end

      def discovery
        @discovery ||= Discovery.new(Seek::Config.omniauth_oidc_issuer)
      end
    end
  end
end
