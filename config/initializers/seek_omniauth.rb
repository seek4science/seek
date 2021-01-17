# use the rails logger for loggin OmniAuth; otherwise it will use std::out
OmniAuth.config.logger = Rails.logger

if Seek::Config.omniauth_enabled
  Rails.application.config.middleware.use OmniAuth::Builder do
    # To add more providers, see the `omniauth_providers` definition in: `lib/seek/config.rb`
    begin
      providers = Seek::Config.omniauth_providers
    rescue Settings::DecryptionError
      providers = {}
    end

    providers.each do |key, options|
      provider key, options
    end
  end
end
