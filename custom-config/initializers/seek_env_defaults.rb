# Override selected Seek::Config defaults for OIDC deployments.
#
# Load order: seek_env_defaults.rb (seek_e) sorts AFTER seek_configuration.rb
# (seek_c, which defines load_seek_config_defaults!) and BEFORE seek_main.rb
# (seek_m, which triggers the first call to Settings.defaults which calls
# load_seek_config_defaults!). So we wrap the method here before it is called.
#
# At load time we only capture a method reference — no Settings or Seek
# constants referenced, safe. When seek_main.rb fires Settings.defaults, our
# wrapped version runs: original defaults first, then ENV overrides on top.

_original_seek_config_defaults = method(:load_seek_config_defaults!)

define_method(:load_seek_config_defaults!) do
  _original_seek_config_defaults.call

  # Disable standard (password) login so only OIDC is presented.
  Settings.defaults[:standard_login_enabled] = false

  # Drive OIDC connection settings from ENV for container deploys.
  # Admin/DB settings still win once persisted.
  Settings.defaults[:omniauth_enabled]        = ENV.fetch('OMNIAUTH_ENABLED', 'false') == 'true'
  Settings.defaults[:omniauth_oidc_enabled]   = ENV.fetch('OMNIAUTH_OIDC_ENABLED', 'false') == 'true'
  Settings.defaults[:omniauth_oidc_name]      = ENV.fetch('OMNIAUTH_OIDC_NAME', 'OpenID Connect Provider')
  Settings.defaults[:omniauth_oidc_issuer]    = ENV.fetch('OMNIAUTH_OIDC_ISSUER', '')
  Settings.defaults[:omniauth_oidc_client_id] = ENV.fetch('OMNIAUTH_OIDC_CLIENT_ID', '')
  Settings.defaults[:omniauth_oidc_secret]    = ENV.fetch('OMNIAUTH_OIDC_SECRET', '')
  Settings.defaults[:omniauth_oidc_scope]     = ENV.fetch('OMNIAUTH_OIDC_SCOPE', 'openid email profile')

  # Group claim → Project sync (in-tree Seek::Omniauth::OidcGroupProjectSync)
  Settings.defaults[:omniauth_oidc_groups_enabled] = ENV.fetch('OMNIAUTH_OIDC_GROUPS_ENABLED',
                                                               ENV.fetch('OMNIAUTH_OIDC_ENABLED', 'false')) == 'true'
  Settings.defaults[:omniauth_oidc_groups_claim] = ENV.fetch('OMNIAUTH_OIDC_GROUPS', 'entitlement')
end
