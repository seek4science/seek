# use the rails logger for loggin OmniAuth; otherwise it will use std::out
OmniAuth.config.logger = Rails.logger
callme = -> {}
if Seek::Config.omniauth_enabled
  callme = -> {
    # To add more providers, see the `omniauth_providers` definition in: `lib/seek/config.rb`
    begin
      providers = Seek::Config.omniauth_providers
    rescue Settings::DecryptionError
      providers = []
    end

    providers.each do |key, options|
      if options.is_a?(Array)
        provider key, *options
      else
        provider key, options
      end
    end
  }
end

Rails.application.config.middleware.use OmniAuth::Builder do
  callme
end
