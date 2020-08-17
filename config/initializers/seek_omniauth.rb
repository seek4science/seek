# use the rails logger for loggin OmniAuth; otherwise it will use std::out
OmniAuth.config.logger = Rails.logger

# Monkey patch for GitHub strategy to pass the access token in the header instead of the query (which is deprecated).
# There is an official release that implements it, but it requires a version of `omniauth` that is incompatible with
# the other omniauth plugins we are using.
module OmniAuth
  module Strategies
    class GitHub
      def raw_info
        access_token.options[:mode] = :header
        @raw_info ||= access_token.get('user').parsed
      end

      def emails
        return [] unless email_access_allowed?
        access_token.options[:mode] = :header
        @emails ||= access_token.get('user/emails', :headers => { 'Accept' => 'application/vnd.github.v3' }).parsed
      end
    end
  end
end

if Seek::Config.omniauth_enabled
  Rails.application.config.middleware.use OmniAuth::Builder do
    # To add more providers, see the `omniauth_providers` definition in: `lib/seek/config.rb`
    begin
      providers = Seek::Config.omniauth_providers
    rescue Settings::DecryptionError
      providers = {}
    end

    providers.each do |key, options|
      if options.is_a?(Array)
        provider key, *options
      else
        provider key, options
      end
    end
  end
end
