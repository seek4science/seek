# use the rails logger for loggin OmniAuth; otherwise it will use std::out
OmniAuth.config.logger = Rails.logger

if Seek::Config.omniauth_enabled
  Rails.application.config.middleware.use OmniAuth::Builder do
    Seek::Config.omniauth_providers.each do |key, options|
      provider key, options
    end
  end
end